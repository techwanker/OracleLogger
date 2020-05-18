set echo on
create table logger_hdr
(
	logger_hdr_id  number(9)    primary key,
        logger_set_nm  varchar(32)  unique not null,
        default_lvl    number(1)    not null
);

create sequence logger_hdr_id_seq;

create table logger_dtl
(
        logger_dtl_id number(9)   primary key,
	logger_hdr_id number(9)   references logger_hdr,
        logger_nm     varchar(132),
        log_lvl       number(1) not null,
        constraint logger_dtl_uniq unique (logger_hdr_id, logger_nm)
);

create sequence logger_dtl_id_seq;



