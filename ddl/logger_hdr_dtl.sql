create or replace view logger_hdr_dtl as
select 
    h.logger_set_nm,
    d.logger_nm,
    d.log_lvl,
    h.default_lvl
from
    logger_hdr h,
    logger_dtl d
where h.logger_hdr_id = d.logger_dtl_id
order by logger_set_nm, logger_nm;
