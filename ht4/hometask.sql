create table parts
(
  inner_number varchar(50)      not null comment 'Совпадает с системным внутренним номером. Товар дублируется из 1с'
    primary key,
  is_original  int(1) default 0 not null comment 'Признак оригинальности. Если товар оригинальный, он не может быть аналогом к другому товару. Т.к. в mysql отсутствует тип boolean, приходится использовать такую конструкцию',
  article      varchar(50)      not null comment 'Артикул товара. Не совпадает с внутренним номером. Это его идентификатор для поиска. Длина указана максимально возможной для данного поля',
  brand        varchar(50)      null,
  title        varchar(255)     not null comment 'Название товара. Например, "тормозной шланг". Длина указана максимально возможной для полнотекстового поиска'
);

create table analogs
(
  article         varchar(50)  not null comment 'Артикул товара. Нужен для поиска по полному или частичному совпадению. Размер указан максимально возможным для данного вида товара',
  title           varchar(255) not null comment 'Название товара. Например "тормозная колодка". Нужен для поиска по частичному вхождению. Указан максимально возможный размер, чтобы сделать полнотекстовый поиск',
  original_number varchar(50)  not null comment 'Системный номер оригинального товара для данного товара. Может быть его собственным номером. Совпадает с максимально возможным размером системного номера',
  constraint analogs_ibfk_1
    foreign key (original_number) references parts (inner_number)
);

create index analogs_article_index
  on analogs (article);

create index analogs_article_title_index
  on analogs (article, title);

create index analogs_title_index
  on analogs (title);

create index original_number
  on analogs (original_number);

create table parts_actual_state
(
  id          bigint unsigned auto_increment,
  part_number varchar(50)                 not null comment 'Внешний ключ для товара с учётом размера поля у товара',
  balance     int            default 0    not null comment 'Остаток товаров на складах, доступный для покупки',
  price       decimal(10, 2) default 0.00 not null comment 'Цена товара. Размер указан для максимально высокой цены. В mysql нет типа money, поэтому приходится использовать такую конструкцию',
  modified    datetime                    null comment 'Т.к. эти данные загружаются извне с помощью апишки, то указано время последнего изменения',
  constraint id
    unique (id),
  constraint parts_actual_state_ibfk_1
    foreign key (part_number) references parts (inner_number)
);

create index part_number
  on parts_actual_state (part_number);

alter table parts_actual_state
  add primary key (id);

create table user_credentials
(
  id            bigint unsigned auto_increment,
  login         varchar(50) not null comment 'Допустимая длина логина. Поле уникально',
  password_hash varchar(64) not null comment 'Указана переменная длина хэша для возможности использования разных алгоритмов',
  password_salt varchar(10) null comment 'Использование соли длиной более 10 символов нецелесообразно',
  constraint id
    unique (id),
  constraint user_credentials_login_uindex
    unique (login)
);

alter table user_credentials
  add primary key (id);

create table cart_items
(
  id             bigint unsigned auto_increment comment 'Предполагается, что заказов может быть очень много. Также предполагается, что корзина может очищаться',
  user_id        bigint unsigned             not null comment 'Айди пользователя. Используется serial, т.к. мне кажется, что это наиболее оптимальный размер для айдишника',
  part_number    varchar(50)                 not null comment 'Совпадает с максимально возможным размером системного имени',
  quantity       int(10)        default 1    not null comment 'Настолько большой диапазон, на случай если будет заказываться большое количество недорогих товаров (например, гайки)',
  price_per_item decimal(10, 2) default 1.00 not null comment 'Т.к. в mysql отсуствует тип money, приходится использовать такой. Цена не может быть меньше 1 рубля, поэтому такое значение по умолчанию',
  constraint id
    unique (id),
  constraint cart_items_ibfk_1
    foreign key (user_id) references user_credentials (id),
  constraint cart_items_ibfk_2
    foreign key (part_number) references parts (inner_number)
);

create index part_number
  on cart_items (part_number);

create index user_id
  on cart_items (user_id);

alter table cart_items
  add primary key (id);

create table orders
(
  id          bigint unsigned auto_increment comment 'По аналогии с предыдущими',
  user_id     bigint unsigned                    not null comment 'Соответствует размеру айдишника пользователя',
  created_at  datetime default CURRENT_TIMESTAMP not null comment 'Проставляется текущая дата как дата создания',
  modified_at datetime                           null,
  constraint id
    unique (id),
  constraint orders_ibfk_1
    foreign key (user_id) references user_credentials (id)
);

create index user_id
  on orders (user_id);

alter table orders
  add primary key (id);

create table order_items
(
  order_id       bigint unsigned             not null comment 'Внешний ключ заказа. Совпадает по размерам с айдишником',
  part_id        varchar(50)                 not null comment 'Внешний ключ запчасти. Совпадает по размеру с айдишником',
  quantity       int(10)        default 1    not null comment 'По количеству аналогично корзине. Заказа не может быть меньше 1',
  price_per_item decimal(15, 2) default 1.00 not null comment 'Цена на случай изменения цены в будущем. Чтобы зафиксировать её в заказе. Диапазон увеличен в связи с тем, что товаров может быть заказано много',
  constraint order_items_ibfk_1
    foreign key (order_id) references orders (id),
  constraint order_items_ibfk_2
    foreign key (part_id) references parts (inner_number)
);

create index order_id
  on order_items (order_id);

create index part_id
  on order_items (part_id);

create table user_data
(
  id        bigint unsigned auto_increment,
  full_name varchar(255)    not null comment 'Т.к. мы не используем отдельно имя, фамилию и отчество, то сохраняем эти данные в одно поле. Длину указываем максимально возможную для полнотекстового поиска',
  user_id   bigint unsigned not null comment 'Совпадает с айдишником пользователя',
  email     varchar(100)    not null comment 'Предполагаем максимальную длину имэйла',
  phone     varchar(30)     not null comment 'Предполагаем максимальную длину номера телефона (включая добавочные)',
  company   varchar(100)    not null comment 'Предполагаем максимальную длину названия компании',
  constraint id
    unique (id),
  constraint user_data_ibfk_1
    foreign key (user_id) references user_credentials (id)
);

create index user_id
  on user_data (user_id);

alter table user_data
  add primary key (id);

