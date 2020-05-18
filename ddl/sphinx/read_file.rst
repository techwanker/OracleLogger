::

    set echo on
    create or replace function read_file(p_dir_name in varchar, p_file_name in varchar) 
    return clob is  
        my_clob         clob;
        my_bfile        bfile;
        my_dest_offset  integer := 1;
        my_src_offset   integer := 1;
        my_lang_context integer := dbms_lob.default_lang_ctx;
        my_warning      integer;
    begin
        dbms_output.put_line('reading ' || p_dir_name || ' ' || p_file_name);
        my_bfile := bfilename(p_dir_name, p_file_name);

        dbms_lob.CreateTemporary(my_clob, FALSE, dbms_lob.CALL);
        dbms_lob.FileOpen(my_bfile);
        dbms_output.put_line('get_tracefile: before LoadClobFromFile');

        dbms_lob.LoadClobFromFile (
                dest_lob     => my_clob,
                src_bfile    => my_bfile,
                amount       => dbms_lob.lobmaxsize,
                dest_offset  => my_dest_offset,
                src_offset   => my_src_offset,
                bfile_csid   => dbms_lob.default_csid,
                lang_context => my_lang_context,
                warning      => my_warning
        );
        dbms_output.put_line('get_tracefile warning: ' || my_warning);
        dbms_lob.FileClose(my_bfile);
        dbms_output.put_line('returning file');
        return my_clob;

end read\_file ; / show errors;
