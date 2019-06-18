start transaction;
select parts.inner_number from parts where parts.inner_number=1 limit 1 for update;
select analogs.original_number from analogs where analogs.original_number=1 limit 1 for update;
update parts set article='121', title='Тормозная колодка' where inner_number=1;
update analogs set article='121' where original_number=1;
commit;