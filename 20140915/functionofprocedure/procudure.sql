create or replace function wx_notify_crowdreply(f_adclientid in number)
    return clob is
    returnclob clob;
    tempsql    varchar2(5000);
    resultja   json_list := new json_list();
    tempjo     json;
    membersja  json_list;
    memberids  varchar2(1000):=null;
    member_reply clob;
begin
  	returnclob:=empty_clob();
		dbms_lob.createtemporary(returnclob,true);
    for f in (select nm.id,nm.wx_notify_id,
                     trim(nvl(nm.massopenid, '')) as condition,nm.ad_client_id
              from   wx_notifymember nm
              --where  nm.ad_client_id = f_adclientid
              where  nm.type=1
              and    nm.state = 'N'
              and    nvl(nm.errcount,0)<=5
							and rownum<=1
							--order by nm.creationdate desc,nm.modifieddate asc
              ) loop
              --dbms_output.put_line(f.wx_notify_id);
        if f.condition is null then
				    update wx_notifymember nm set nm.modifieddate=sysdate,nm.errcount=nvl(nm.errcount,0)+1,nm.errorlog='massopenid is null' where nm.id=f.id;
            continue;
        end if;
				begin
						tempsql      := 'select v.wechatno as "openid" from wx_vip v where v.ad_client_id=' ||
														f.ad_client_id || ' and v.id ' || f.condition;
		    exception when others then
				    update wx_notifymember nm set nm.modifieddate=sysdate,nm.errcount=nvl(nm.errcount,0)+1,nm.errorlog='condition is too large' where nm.id=f.id;
            continue;
				end;
        membersja    := json_dyn.executelist(tempsql);
        member_reply := wx_notify_$r_reply(f.ad_client_id, f.id,1);
        dbms_output.put_line(member_reply);
        if member_reply is null or membersja.count<=0 then
           update wx_notifymember nm set nm.modifieddate=sysdate,nm.errcount=nvl(nm.errcount,0)+1,nm.errorlog='reply is null or member is null' where nm.id=f.id;
           continue;
        end if;
        tempjo       := new json();
        begin
            tempjo.put('id', f.id);
            tempjo.put('reply', new json(member_reply));
            tempjo.put('members', membersja.to_json_value);
            tempjo.put('ad_client_id',f.ad_client_id);
            resultja.add_elem(tempjo.to_json_value);
            dbms_output.put_line(tempjo.to_char);
            --resultja.to_clob(returnclob,true);
        exception when others then
            update wx_notifymember nm set nm.modifieddate=sysdate,nm.errcount=nvl(nm.errcount,0)+1,nm.errorlog='init jo error' where nm.id=f.id;
            dbms_output.put_line(sqlerrm);
        end;
        if memberids is null then
           memberids:='';
        else
           memberids:=memberids||',';
        end if;
        memberids:=memberids||f.id;
    end loop;
    begin
        resultja.to_clob(returnclob,false);
    exception when others then
        update wx_notifymember nm set nm.modifieddate=sysdate,nm.errcount=nvl(nm.errcount,0)+1,nm.errorlog='to_clob error' where nm.id in(memberids);
        dbms_output.put_line(sqlerrm);
    end;
    return returnclob;
end;

/
create or replace procedure AD_CLIENT_Drop(v_id in number) is

    /**
    * Drop 一个client, 包括以下内容：
    * 所有在ad_table 中定义有ad_client_id的表（非view）
    * YFZHU 2005-04-24
      yfhzu 2008-08-20 5次尝试删除，仍失败时写日志
    */
    --  v_id             number(10);
   -- pCTX             PLOG.LOG_CTX := PLOG.init('AD_CLIENT_Drop', PLOG.LINFO);
    v_Code           number(10);
    v_message        varchar2(4000);
    v_vnt1           varchar2(4000);
    v_vnt2           varchar2(4000);
    v_partition_name varchar2(32767);
    v_domain         varchar2(4000);
begin
    select domain into v_domain from ad_client where id = v_id;
    delete from WX_SETINFO t where t.ad_client_id=v_id;
    delete from WX_ITEMARTICLECATEGORY t where t.ad_client_id=v_id;
    delete from WX_SETCOLUMN t where t.ad_client_id=v_id;
    delete from WX_ARTICLECATEGORY t where t.ad_client_id=v_id;
    delete from WX_SETAD t where t.ad_client_id=v_id;
    delete from WX_ISSUEARTICLE t where t.ad_client_id=v_id;
    delete from WX_ITEMCATEGORYSET t where t.ad_client_id=v_id;
		delete from WX_GROUPON t where t.ad_client_id=v_id;
    delete from WX_PDT_IMAGE t where t.ad_client_id=v_id;
    delete from WX_COMMENT t where t.ad_client_id=v_id;
		delete from WX_PRODUCTCATEGORY t where t.ad_client_id=v_id;
    delete from WX_APPENDGOODS t where t.ad_client_id=v_id;
    delete from WX_ADDRESS t where t.ad_client_id=v_id;
    delete from WX_ALIAS t where t.ad_client_id=v_id;
    delete from WX_DEAL t where t.ad_client_id=v_id;
    delete from WX_SPEC t where t.ad_client_id=v_id;
    delete from WX_DISTRIBUTION t where t.ad_client_id=v_id;
    delete from WX_EXPRESSCOST t where t.ad_client_id=v_id;
    delete from WX_LOGISTICSCOST t where t.ad_client_id=v_id;
    delete from WX_PAY t where t.ad_client_id=v_id;
    delete from WX_SPECITEM t where t.ad_client_id=v_id;
    delete from WX_ORDERWAY t where t.ad_client_id=v_id;
    delete from WX_ORDER t where t.ad_client_id=v_id;
    delete from WX_ORDERITEM t where t.ad_client_id=v_id;
    delete from WX_ORDER_INQURY t where t.ad_client_id=v_id;
    delete from WX_ORDER_INQURYNOW t where t.ad_client_id=v_id;
    delete from WX_ORDER_INTEGRAL t where t.ad_client_id=v_id;
    delete from WX_SHOPPING t where t.ad_client_id=v_id;
    delete from WX_MALL t where t.ad_client_id=v_id;
   -- delete from WX_COMMENT_GROUP t where t.ad_client_id=v_id;
    delete from WX_VIPCASESET t where t.ad_client_id=v_id;
    delete from WX_VIPBASESET t where t.ad_client_id=v_id;
    delete from WX_BINDCARD t where t.ad_client_id=v_id;
		delete from wx_scratchcard_record t where t.ad_client_id=v_id;
		delete from wx_scratchcard_coupon t where t.ad_client_id=v_id;
		delete from wx_scratchcard_award t where t.ad_client_id=v_id;
    delete from WX_SCRATCHCARD t where t.ad_client_id=v_id;
		delete from WX_VIPMONEY t where t.ad_client_id=v_id;
    delete from WX_VIP t where t.ad_client_id=v_id;
    delete from WX_VIPINFO t where t.ad_client_id=v_id;
    delete from WX_VIPMONEY t where t.ad_client_id=v_id;
    delete from WX_VIP_INQURY t where t.ad_client_id=v_id;
    delete from WX_INTEGRAL t where t.ad_client_id=v_id;
    delete from WX_INTERFACESET t where t.ad_client_id=v_id;
    delete from WX_MEDIA t where t.ad_client_id=v_id;
    delete from WX_MENUSET t where t.ad_client_id=v_id;
    delete from TEXTMODE t where t.ad_client_id=v_id;
    delete from WX_SINGLEIMAGETEXT t where t.ad_client_id=v_id;
    delete from WX_MOREIMAGETEXT t where t.ad_client_id=v_id;
    delete from WX_ATTENTIONSET t where t.ad_client_id=v_id;
    delete from WX_ATTENTIONSETITEM t where t.ad_client_id=v_id;
    delete from WX_MESSAGEAUTO t where t.ad_client_id=v_id;
    delete from WX_MESSAGEAUTOITEM t where t.ad_client_id=v_id;
    delete from WX_MESSAGEAUTOONE t where t.ad_client_id=v_id;
    delete from WX_MESSAGEAUTOQ t where t.ad_client_id=v_id;
    delete from WX_NOITFYITEM t where t.ad_client_id=v_id;
    delete from WX_NOTIFY t where t.ad_client_id=v_id;
    delete from WX_MESSGAE t where t.ad_client_id=v_id;
    --delete from WX_KEYWORDSET t where t.ad_client_id=v_id;
    delete from WX_NOTIFYMEMBER t where t.ad_client_id=v_id;
    delete from WX_APP t where t.ad_client_id=v_id;
    delete from WX_SCRATCHCARD_AWARD t where t.ad_client_id=v_id;
    delete from WX_NAVIGATION t where t.ad_client_id=v_id;
    delete from WX_SCRATCHCARD_COUPON t where t.ad_client_id=v_id;
    delete from WX_DIAL t where t.ad_client_id=v_id;
    delete from WX_SCRATCHCARD_RECORD t where t.ad_client_id=v_id;
		delete from WX_SENDCOUPON t where t.ad_client_id=v_id;
    delete from WX_COUPON t where t.ad_client_id=v_id;
    delete from WX_COUPONEMPLOY t where t.ad_client_id=v_id;
    delete from WX_ALBUMSET t where t.ad_client_id=v_id;
    delete from WX_SUBSCRIBE t where t.ad_client_id=v_id;
    delete from WX_ALBUM t where t.ad_client_id=v_id;
    delete from WX_ALBUMMANAGE t where t.ad_client_id=v_id;
    delete from WX_SUBSCRIBERECORD t where t.ad_client_id=v_id;
    delete from WX_LOTTERY t where t.ad_client_id=v_id;
    delete from WX_WINNING t where t.ad_client_id=v_id;
    delete from WX_PRIZE t where t.ad_client_id=v_id;
    delete from WX_MESSAGEBOARDSET t where t.ad_client_id=v_id;
    delete from WX_MESSAGEBORADLIST t where t.ad_client_id=v_id;
    delete from WX_BLACKLIST t where t.ad_client_id=v_id;
    delete from WEB_CLIENT_TMP t where t.AD_CLIENT_ID = v_id;
    delete from WX_INTERFACESET t where t.ad_client_id = v_id;
    delete from WX_REGUSER t where t.WXAPPID = v_domain;
    delete from ad_client t where t.ad_client_id = v_id;
    delete from WEB_CLIENT_TMP t where t.ad_client_id = v_id;
    delete from WEB_MAIL_TMP t where t.ad_client_id = v_id;
    delete from WEB_CLIENT t where t.ad_client_id = v_id;
		delete from WX_SCRATCHTICKET_NOTE t where t.ad_client_id=v_id;
		delete from WX_SCRATCHREWARD t where t.ad_client_id=v_id;
		delete from WX_SCRATCHTICKET t where t.ad_client_id=v_id;
		delete from wx_towxmessageitem t where t.ad_client_id=v_id;
    delete from wx_towxmessage t where t.ad_client_id=v_id;
		delete from wx_notifyrecode t where t.ad_client_id=v_id;
    /*
    select t.partition_name
    into v_partition_name
    from dba_segments t
    where tablespace_name = p_tablefile and rownum = 1;
    /*
    select t.partition_name
    into v_partition_name
    from user_tab_partitions t
    where t.tablespace_name = upper(p_tablefile) and rownum = 1;
     */
    -- drop users in lportal
    delete from users_roles@lportal
    where userid in
          (select email || '@' || v_domain from users where ad_client_id = v_id);
    delete from users_usergroups@lportal
    where userid in
          (select email || '@' || v_domain from users where ad_client_id = v_id);
    delete from group_@lportal
    where classpk in
          (select email || '@' || v_domain from users where ad_client_id = v_id) and
          classname = 'com.liferay.portal.model.User';
    delete from contact_@lportal
    where userid in
          (select email || '@' || v_domain from users where ad_client_id = v_id);
    delete from user_@lportal
    where userid in
          (select email || '@' || v_domain from users where ad_client_id = v_id);
  delete from users t where t.ad_client_id = v_id;
    delete from ad_client t where t.ad_client_id = v_id;
    -- 如果A表数据被B表引用，在B表数据未被删除的情况下，导致A表数据也不能成功被删除，这样要删除A表就要等做完B表后再做一次
    -- 如果这样的引用还有C表，必须做3次删除，有D表，做4次，依次类推，这里做5次
    /*
    FOR i IN 1 .. 5 LOOP
        for v in (select name
                  from ad_table@nds3 t
                  where is_virtual_table(id, 1) = 0 and exists
                   (select 1
                         from ad_column
                         where ad_table_id = t.id and dbname = 'AD_CLIENT_ID') and
                        t.name not like 'A%' and t.name not like 'G%' and
                        t.name not like 'U%') loop
            BEGIN
                execute immediate ' alter table ' || v.name ||
                                  ' disable all triggers';
                execute immediate 'insert into ' || v.name || ' select * from ' ||
                                  v.name || '@nds3';
            EXCEPTION
                WHEN OTHERS THEN
                    v_Code    := SQLCODE;
                    v_Message := SQLERRM;
                    if i = 5 then
                        -- 只在最后一次写日志
                        PLOG.info(pCTX,
                                  'delete from ' || v.name ||
                                  ' where ad_client_id=' || v_id || ', failed:' ||
                                  v_message || '(' || v_code || ')');
                    end if;
            END;
        end loop;
    end loop;
    /*
       for v in (select table_name, partition_name
                 from user_tab_partitions
                 where partition_name = v_partition_name) loop
           --execute immediate
           dbms_output.put_line(v.table_name);
           --  alter table AD_CXTAB_CATEGORY enable all triggers;
           execute immediate 'delete from ' || v.table_name ||
                             ' where ad_client_id=' || v_id;
           execute immediate 'alter table ' || v.table_name || ' drop partition ' ||
                             v_partition_name;
       end loop;
       execute immediate 'drop tablespace ' || upper(p_tablefile) ||
                         ' including CONTENTS and datafiles cascade constraint';
    */
end;

/
create or replace FUNCTION wx_rqcodemessage_$r_scan(p_user_id IN NUMBER,

                                                p_query   IN VARCHAR2)
    RETURN CLOB IS
    --------------------------------------------------------------
    --ADD BY PACO 20140924
    --扫描二维码处理
    --------------------------------------------------------------
    st_xml VARCHAR2(32676);
    v_xml  xmltype;
    TYPE t_queryobj IS RECORD(
        fromusername VARCHAR2(200),
        tousername   VARCHAR2(200),
        msgtype      VARCHAR2(80),
        eventkey     VARCHAR2(200),
				ticket       varchar2(200));
    v_queryobj t_queryobj;
    v_eventkey     VARCHAR2(1500);
    v_fromusername VARCHAR2(200);
    v_tousername   VARCHAR2(200);
    v_mstype       VARCHAR2(80);
    v_medier_id    VARCHAR2(100);
    v_count       NUMBER(10);
    v_client_id    NUMBER(10);
    jos1         json;
    joslist      json_list := NEW json_list;
    contentstr   VARCHAR2(4000);
    v_fid        NUMBER(10);
    v_odreplace  VARCHAR2(4000);
    v_replace    VARCHAR2(4000);
    v_receive    VARCHAR2(4000);
    v_url        VARCHAR2(4000);
    v_url1       VARCHAR2(4000);
    v_content    VARCHAR2(4000);
    v_sr1        VARCHAR2(4000);
    v_sr2        VARCHAR2(4000);
    v_appid      VARCHAR2(100);
    v_publictype CHAR(1);
		v_ticket     varchar2(200);
    v_domain     VARCHAR2(4000);
		v_actiontype varchar2(100);
    v_wx_rqcodemessage wx_rqcodemessage%ROWTYPE;
BEGIN
    -- 从p_query解析数据
    st_xml := p_query;
    v_xml := xmltype(st_xml);
    SELECT extractvalue(VALUE(t), '/xml/FromUserName'),
           extractvalue(VALUE(t), '/xml/ToUserName'),
           extractvalue(VALUE(t), '/xml/MsgType'),
           extractvalue(VALUE(t), '/xml/EventKey'),
					 extractvalue(VALUE(t), '/xml/Ticket')
    INTO v_queryobj
    FROM TABLE(xmlsequence(extract(v_xml, '/xml'))) t;
		v_ticket:=v_queryobj.ticket;
    v_eventkey := v_queryobj.eventkey;
    v_fromusername := v_queryobj.fromusername;
    v_tousername := v_queryobj.tousername;
    --raise_application_error(-20014, 'ad_client_id:' || p_user_id || p_query);
    v_client_id := p_user_id;
    SELECT COUNT(*)
    INTO v_count
    FROM wx_rqcodemessage t
    WHERE t.rqcodeparam = v_eventkey
    AND t.isenable = 'Y'
    AND t.ad_client_id = v_client_id;
    IF v_count <> 0 THEN
        SELECT *
        INTO v_wx_rqcodemessage
        FROM wx_rqcodemessage t
        WHERE t.rqcodeparam = v_eventkey
        AND t.isenable = 'Y'
        AND t.ad_client_id = v_client_id;
        SELECT s.appid, s.publictype
        INTO v_appid, v_publictype
        FROM wx_interfaceset s
        WHERE s.ad_client_id = v_client_id;
        SELECT 'http://'||wc.domain
        INTO v_domain
        FROM web_client wc
        WHERE wc.ad_client_id = v_client_id;
        IF v_publictype = '4' THEN
           v_sr1 := 'https://open.weixin.qq.com/connect/oauth2/authorize?appid=' ||
                     v_appid || '&redirect_uri=';
           v_sr2 := '&response_type=code&scope=snsapi_base&state=1#wechat_redirect';
        ELSE
           v_sr1:='';
           v_sr2:='';
        END IF;
        IF v_wx_rqcodemessage.msgtype = 'Words' THEN
            /* <xml>
            <ToUserName><![CDATA[toUser]]></ToUserName>
            <FromUserName><![CDATA[fromUser]]></FromUserName>
            <CreateTime>12345678</CreateTime>
            <MsgType><![CDATA[text]]></MsgType>
            <Content><![CDATA[你好]]></Content>
            </xml> */
            --jos := json(v_wx_messageauto.urlcontent);
            v_content := v_wx_rqcodemessage.content;
            --joslist := json_ext.get_json_list(jos, 'list');
            IF v_wx_rqcodemessage.urlcontent IS NOT NULL THEN
                BEGIN
                   joslist := json_list(v_wx_rqcodemessage.urlcontent);
                EXCEPTION WHEN OTHERS THEN
                   joslist :=json_list();
               END;
                FOR v IN 1 .. joslist.count LOOP
                    jos1 := json(joslist.get_elem(v));
                    v_fid := jos1.get('fromid').get_number;
                    v_odreplace := jos1.get('oldreplace').get_string;
                    v_replace := jos1.get('replace').get_string;
                    v_receive := jos1.get('receive').get_string;
                    BEGIN
                      SELECT t.purl
                      INTO v_url
                      FROM wx_v_jumpurlpath t
                      WHERE t.id = v_fid+v_client_id and t.ad_client_id=v_client_id;
                    EXCEPTION WHEN no_data_found THEN
                      v_url:=NULL;
                      v_replace:='#';
                    END;
                    IF v_url IS NULL THEN
                        v_url1 := v_replace;
                    ELSE
                        v_url1 := v_sr1 ||v_domain || REPLACE(v_url, v_odreplace, v_replace)|| v_sr2;
                    END IF;
                    contentstr := v_content;
                    v_content := REPLACE(contentstr, v_receive, v_url1);
                END LOOP;
            END IF;
            v_mstype := 'text';
            SELECT xmlelement("xml",
                               xmlelement("ToUserName",
                                           xmlcdata(v_fromusername) "XMLCData"),
                               xmlelement("FromUserName",
                                           xmlcdata(v_tousername) "XMLCData"),
                               xmlelement("CreateTime",
                                           to_char(SYSDATE, 'yyyymmddhhmiss')),
                               xmlelement("MsgType", xmlcdata(v_mstype) "XMLCData"),
                               xmlelement("Content",
                                           xmlcdata(v_content /*v_wx_messageauto.content*/)
                                            "XMLCData"))
            INTO v_xml
            FROM dual;
            -- raise_application_error(-20014, 'test');
        ELSIF v_wx_rqcodemessage.msgtype = 'Image' THEN
            /* <xml>
            <ToUserName><![CDATA[toUser]]></ToUserName>
            <FromUserName><![CDATA[fromUser]]></FromUserName>
            <CreateTime>12345678</CreateTime>
            <MsgType><![CDATA[image]]></MsgType>
            <Image>
            <MediaId><![CDATA[media_id]]></MediaId>
            </Image>
            </xml>*/
            v_mstype := 'image';
            SELECT b.media_id
            INTO v_medier_id
            FROM wx_messageautoq a, wx_media b
            WHERE a.id = v_wx_rqcodemessage.id
            AND a.wx_media_id = b.id
            AND a.ad_client_id = b.ad_client_id
            AND a.ad_client_id = v_client_id;
            SELECT xmlelement("xml",
                               xmlelement("ToUserName",
                                           xmlcdata(v_fromusername) "XMLCData"),
                               xmlelement("FromUserName",
                                           xmlcdata(v_tousername) "XMLCData"),
                               xmlelement("CreateTime", SYSDATE),
                               xmlelement("MsgType", xmlcdata(v_mstype) "XMLCData"),
                               xmlelement("Image",
                                           xmlelement("MediaId",
                                                       xmlcdata(v_medier_id)
                                                        "XMLCData")))
            INTO v_xml
            FROM dual;
            --raise_application_error(-20014, 'test');
        ELSIF v_wx_rqcodemessage.msgtype = 'Voice' THEN
            /*<xml>
            <ToUserName><![CDATA[toUser]]></ToUserName>
            <FromUserName><![CDATA[fromUser]]></FromUserName>
            <CreateTime>12345678</CreateTime>
            <MsgType><![CDATA[voice]]></MsgType>
            <Voice>
            <MediaId><![CDATA[media_id]]></MediaId>
            </Voice>
            </xml>*/
            v_mstype := 'voice';
            SELECT b.media_id
            INTO v_medier_id
            FROM wx_messageautoq a, wx_media b
            WHERE a.id = v_wx_rqcodemessage.id
            AND a.wx_media_id = b.id
            AND a.ad_client_id = b.ad_client_id
            AND a.ad_client_id = v_client_id;
            SELECT xmlelement("xml",
                               xmlelement("ToUserName",
                                           xmlcdata(v_fromusername) "XMLCData"),
                               xmlelement("FromUserName",
                                           xmlcdata(v_tousername) "XMLCData"),
                               xmlelement("CreateTime",
                                           to_char(SYSDATE, 'yyyymmddhhmiss')),
                               xmlelement("MsgType", xmlcdata(v_mstype) "XMLCData"),
                               xmlelement("Voice",
                                           xmlelement("MediaId",
                                                       xmlcdata(v_medier_id)
                                                        "XMLCData")))
            INTO v_xml
            FROM dual;
            --raise_application_error(-20014, 'test');
        ELSIF v_wx_rqcodemessage.msgtype = 'Video' THEN
            /*<xml>
            <ToUserName><![CDATA[toUser]]></ToUserName>
            <FromUserName><![CDATA[fromUser]]></FromUserName>
            <CreateTime>12345678</CreateTime>
            <MsgType><![CDATA[video]]></MsgType>
            <Video>
            <MediaId><![CDATA[media_id]]></MediaId>
            <Title><![CDATA[title]]></Title>
            <Description><![CDATA[description]]></Description>
            </Video>
            </xml>*/
            v_mstype := 'video';
            SELECT b.media_id
            INTO v_medier_id
            FROM wx_messageautoq a, wx_media b
            WHERE a.id = v_wx_rqcodemessage.id
            AND a.wx_media_id = b.id
            AND a.ad_client_id = b.ad_client_id
            AND a.ad_client_id = v_client_id;
            SELECT xmlelement("xml",
                               xmlelement("ToUserName",
                                           xmlcdata(v_fromusername) "XMLCData"),
                               xmlelement("FromUserName",
                                           xmlcdata(v_tousername) "XMLCData"),
                               xmlelement("CreateTime",
                                           to_char(SYSDATE, 'yyyymmddhhmiss')),
                               xmlelement("MsgType", xmlcdata(v_mstype) "XMLCData"),
                               xmlelement("Video",
                                           xmlelement("MediaId",
                                                       xmlcdata(v_medier_id)
                                                        "XMLCData"),
                               xmlelement("Title",
                                           xmlcdata(v_wx_rqcodemessage.title)
                                            "XMLCData"),
                               xmlelement("Description",
                                           xmlcdata(v_wx_rqcodemessage.content)
                                            "XMLCData")))
            INTO v_xml
            FROM dual;
            --raise_application_error(-20014, 'test');
        ELSIF v_wx_rqcodemessage.msgtype = 'Music' THEN
            /*<xml>
            <ToUserName><![CDATA[toUser]]></ToUserName>
            <FromUserName><![CDATA[fromUser]]></FromUserName>
            <CreateTime>12345678</CreateTime>
            <MsgType><![CDATA[music]]></MsgType>
            <Music>
            <Title><![CDATA[TITLE]]></Title>
            <Description><![CDATA[DESCRIPTION]]></Description>
            <MusicUrl><![CDATA[MUSIC_Url]]></MusicUrl>
            <HQMusicUrl><![CDATA[HQ_MUSIC_Url]]></HQMusicUrl>
            <ThumbMediaId><![CDATA[media_id]]></ThumbMediaId>
            </Music>
            </xml>*/
            v_mstype := 'music';
            SELECT b.media_id
            INTO v_medier_id
            FROM wx_messageautoq a, wx_media b
            WHERE a.id = v_wx_rqcodemessage.id
            AND a.wx_media_id = b.id
            AND a.ad_client_id = b.ad_client_id
            AND a.ad_client_id = v_client_id;
                                            "XMLCData"),
            SELECT xmlelement("xml",
                               xmlelement("ToUserName",
                                           xmlcdata(nvl(v_fromusername, ' '))
                               xmlelement("FromUserName",
                                           xmlcdata(v_tousername) "XMLCData"),
                               xmlelement("CreateTime",
                                           to_char(SYSDATE, 'yyyymmddhhmiss')),
                               xmlelement("MsgType", xmlcdata(v_mstype) "XMLCData"),
                               xmlelement("Music",
                                           xmlelement("Title",
                                                       xmlcdata(v_wx_rqcodemessage.title)
                                                        "XMLCData"),
                                           xmlelement("Description",
                                                       xmlcdata(v_wx_rqcodemessage.content)
                                                        "XMLCData"),
                                           xmlelement("MusicUrl",
                                                       xmlcdata(v_wx_rqcodemessage.url)
                                                        "XMLCData"),
                                           xmlelement("HQMusicUrl",
                                                       xmlcdata(v_wx_rqcodemessage.hurl)
                                                        "XMLCData"),
                                           xmlelement("ThumbMediaId",
                                                       xmlcdata(v_medier_id)
                                                        "XMLCData")))
            INTO v_xml
            FROM dual;
            --raise_application_error(-20014, 'test');
        ELSIF v_wx_rqcodemessage.msgtype = 'News' THEN
            /*<xml>
            <ToUserName><![CDATA[toUser]]></ToUserName>
            <FromUserName><![CDATA[fromUser]]></FromUserName>
            <CreateTime>12345678</CreateTime>
            <MsgType><![CDATA[news]]></MsgType>
            <ArticleCount>2</ArticleCount>
            <Articles>
            <item>
            <Title><![CDATA[title1]]></Title>
            <Description><![CDATA[description1]]></Description>
            <PicUrl><![CDATA[picurl]]></PicUrl>
            <Url><![CDATA[url]]></Url>
            </item>
            <item>
            <Title><![CDATA[title]]></Title>
            <Description><![CDATA[description]]></Description>
            <PicUrl><![CDATA[picurl]]></PicUrl>
            <Url><![CDATA[url]]></Url>
            </item>
            </Articles>
            </xml> */
            --raise_application_error(-20014, v_wx_messageauto.count);
            v_mstype := 'news';
            SELECT xmlelement("xml",
                               xmlelement("ToUserName",
                                           xmlcdata(nvl(v_fromusername, ' '))
                                            "XMLCData"),
                               xmlelement("FromUserName",
                                           xmlcdata(nvl(v_tousername, ' '))
                                            "XMLCData"),
                               xmlelement("CreateTime",
                                           to_char(SYSDATE, 'yyyymmddhhmiss')),
                               xmlelement("MsgType", xmlcdata(v_mstype) "XMLCData"),
                               xmlelement("ArticleCount", v_wx_rqcodemessage.count),
                               xmlelement("Articles"))
            INTO v_xml
            FROM dual;
            SELECT appendchildxml(v_xml, 'xml/Articles',
                                   xmlagg(xmlelement("item",
                                                      (xmlforest(xmlcdata(nvl(s.title,
                                                                               ' ')) AS
                                                                  "Title",
                                                                  xmlcdata(nvl(s.content,
                                                                                ' ')) AS
                                                                   "Description",
																																	 xmlcdata(case when instr(s.url,'@',1,1)>0 then replace(nvl(s.url,''),'@','') else nvl(v_domain||s.url,'') end)
                                                                   AS
                                                                   "PicUrl",
                                                                  xmlcdata(CASE
                                                                                WHEN nvl(vj.url,'') = '' THEN
                                                                                 CASE WHEN vj.id is NULL THEN '#'
                                                                                 ELSE nvl(s.objid, ' ')
                                                                                 END
                                                                                ELSE
                                                                                v_sr1||case when v_publictype='4'
                                                                                         ||v_sr2
                                                                                                          then replace(apex_util.url_encode(replace(v_domain||nvl(vj.purl,''), '@ID@', nvl(s.objid, ' '))),'%2E','.')
                                                                                                          else replace(nvl(v_domain||vj.purl,''), '@ID@', nvl(s.objid, ' '))
                                                                                                     end
                                                                            END) AS
                                                                   "Url"))) ORDER BY
                                           s.sort asc))
            INTO v_xml
            FROM wx_rqcodemessageitem s LEFT JOIN wx_v_jumpurlpath vj ON vj.id = s.fromid+v_client_id
            WHERE s.wx_rqcodemessage_id = v_wx_rqcodemessage.id and s.ad_client_id=v_client_id and vj.ad_client_id=v_client_id order by s.sort asc;
        ELSIF v_wx_rqcodemessage.msgtype = 'Action' THEN
				    v_mstype := 'action';
						v_actiontype:=v_wx_rqcodemessage.actiontype;
						v_content:=to_char(v_wx_rqcodemessage.content);
            SELECT xmlelement("xml",
                               xmlelement("ToUserName",xmlcdata(v_fromusername) "XMLCData"),
                               xmlelement("FromUserName",xmlcdata(v_tousername) "XMLCData"),
                               xmlelement("CreateTime",to_char(SYSDATE, 'yyyymmddhhmiss')),
                               xmlelement("MsgType", xmlcdata(v_mstype) "XMLCData"),
                               xmlelement("Content",xmlcdata(v_content) "XMLCData"),
															 xmlelement("ActionType",xmlcdata(v_actiontype) "XMLCData")
															 )
            INTO v_xml
            FROM dual;
				END IF;
        --raise_application_error(-20014, 'test');
    END IF;
    RETURN v_xml.getclobval();
EXCEPTION
    WHEN OTHERS THEN
        RETURN '<xml>null</xml>';
END;

/
create or replace PROCEDURE wx_appendgoods_am(p_id IN NUMBER) AS

    -------------------------------------------------------------------------
    --add by zwm 20140401
    -------------------------------------------------------------------------
    str1 VARCHAR2(1500);
    str2 CLOB;
    --str3 CLOB;
    jl   json_list := NEW json_list;
    jo   json;
    v_id VARCHAR2(80);
    j2  json_list := NEW json_list;
    --j3  json_list := NEW json_list;
    --jo2 json;
    --v_sapcetemp    number(10);
    --v_spacecode           varchar2(100);
    --wx_aliasid      NUMBER(10);
    --v_name          VARCHAR2(200);
    v_spec          VARCHAR2(500);
    --v_wx_alias_code VARCHAR2(500);
    --v_qty           NUMBER(10);
		--v_lockqty       number(10);
    --v_pricelist     NUMBER(16, 2);
    --v_priceactual   NUMBER(16, 2);
    --v_weight        NUMBER(16, 2);
    --v_issale        CHAR(3);
		v_count         number(10);
		v_ad_client_id  number(10);
    v_image         varchar2(500);
    v_images        varchar2(500);
		f_default_qty  number(10);
		f_all_qty    number(10);
		f_all_count  number(10);
		f_sqls       varchar2(1000);
BEGIN
    --删除原有所属分类
    --DELETE FROM wx_productcategory t
    --WHERE t.wx_appendgoods_id = p_id;
    SELECT t.productcategory,t.spec,t.ad_client_id
    INTO str1,v_spec,v_ad_client_id
    FROM wx_appendgoods t
    WHERE id = p_id;
    --如果商品编号不为空，则判断是否唯一
		if nvl(v_spec,null) is not null then
				if REGEXP_LIKE(v_spec,'^[A-Za-z0-9]+$')=false then
					 raise_application_error(-20201,'商品编号只能由数字与字母组成');
				end if;
				--判断商品编号是否唯一
				select count(1)
				into v_count
				from wx_appendgoods ag
				where ag.id<>p_id
				and ag.ad_client_id=v_ad_client_id
				and ag.spec=v_spec;
				if v_count>0 then
					 raise_application_error(-20201,'商品编号已存在，请重新输入！');
				end if;
		end if;
    --raise_application_error(-20014, str1);
    begin
		    jo:=json(str1);
				if jo.exist('ids') then
				   str1:=jo.get('ids').get_string;
				end if;
		    --设置商品所属分类
		    f_sqls:='update wx_productcategory pc set pc.wx_appendgoods_id='||p_id||'  where pc.id in ('||str1||')';
				execute immediate f_sqls;
				commit;
		exception when others then
		     null;
		end;
    /*jl := json_list(str1);
    FOR i IN 1 .. jl.count LOOP
        jo := json(jl.get_elem(i));
        v_id := jo.get('id').get_number;
        --raise_application_error(-20014, jo.get('id').get_number);
        INSERT INTO wx_productcategory
            (id, ad_client_id, ad_org_id, wx_appendgoods_id, creationdate,
             modifieddate, isactive, wx_itemcategoryset_id,modifierid)
            SELECT get_sequences('WX_PRODUCTCATEGORY'), w.ad_client_id,
                   w.ad_org_id, p_id, SYSDATE, SYSDATE, 'Y', v_id,w.modifierid
            FROM wx_appendgoods w
            WHERE w.id = p_id;
    END LOOP;*/
		--修改默认库存的金额与数量
		update wx_alias a set (a.qty,a.pricelist,a.priceactual)
		                =(select ag.remainnum,ag.itemunitprice,ag.priceactual from wx_appendgoods ag where ag.id=p_id)
		where a.wx_appendgoods_id=p_id
		and   a.isdefault='Y';
		--查询默认条码库存数量
		select nvl(sum(nvl(a.qty,0)),0)
		into f_default_qty
		from wx_alias a
		where a.wx_appendgoods_id=p_id
		and a.isdefault='Y';
		--查询所有条码库存
		select nvl(sum(nvl(a.qty,0)),0),count(1)
		into f_all_qty,f_all_count
		from wx_alias a
		where a.wx_appendgoods_id=p_id
		and a.isdefault='N';
		--修改商品库存
		update wx_appendgoods ag set ag.remainnum=case when f_all_count>0 then f_all_qty else f_default_qty end
		where ag.id=p_id;
    --存储图片路径
   select t.productpics
    into str2
    from WX_APPENDGOODS t
    where t.id = p_id;
    IF str2 IS NOT NULL THEN
      --str3 := '['||str2||']';
      j2 :=json_list(str2);
       FOR i IN 1 .. j2.count LOOP
            v_image:=j2.get_elem(i).get_string;
           if v_image IS NOT NULL THEN
           v_images:='/servlets/userfolder/WX_APPENDGOODS/'||v_image;
             END if;
           INSERT INTO wx_pdt_image
           (id,ad_client_id,ad_org_id,wx_appendgoods_id,image,ownerid,modifierid,creationdate,modifieddate,isactive)
           select get_sequences('Wx_Pdt_Image'),s.ad_client_id,s.ad_org_id,s.id,v_images,s.ownerid,s.modifierid,sysdate,sysdate, 'Y'
            FROM wx_appendgoods s
             where s.id= p_id;
              END LOOP;
       END if;
		--商品条码
   /* SELECT t.spec_description
    INTO str2
    FROM wx_appendgoods t
    WHERE t.id = p_id;
    IF str2 IS NOT NULL THEN
        jo2 := json(str2);
        j2 := json_ext.get_json_list(jo2, 'child');
        --raise_application_error(-20014,j2.get_elem(1).to_char);
        FOR v IN 1 .. j2.count LOOP
            jo3 := json(j2.get_elem(v));
            v_wx_alias_code := jo3.get('sku').get_string;
						if nvl(v_wx_alias_code,'')='' then
						   raise_application_error(-20201,'货号不能为空！');
						end if;
						if regexp_like(v_wx_alias_code,'^[A-Za-z0-9]+$')=false then
						   raise_application_error(-20201,'货号只能由数字与字母组成');
						end if;
						--判断条码是否存在
						select count(1)
						into v_count
						from wx_alias a
						where a.ad_client_id=v_ad_client_id
						and a.wx_alias_code=v_wx_alias_code;
						if v_count>0 then
						   raise_application_error(-20201,'货号已存在，请重新输入！');
						end if;
            j3 := json_ext.get_json_list(jo3, 'space');
            v_qty := jo3.get('inventory').get_number;
						v_lockqty:=jo3.get('lockinventory').get_number;
            v_pricelist := jo3.get('costprice').get_number;
            v_priceactual := jo3.get('sellprice').get_number;
            v_weight := jo3.get('wheight').get_number;
            v_issale := jo3.get('putaway').get_string;
            v_spec := NULL;
						v_spacecode:='';
            FOR j IN 1 .. j3.count LOOP
                jo4 := json(j3.get_elem(j));
                --raise_application_error(-20014,jo4.to_char);
                v_name := jo4.get('name').get_string;
                v_spec := v_spec || '/' || v_name;
                v_sapcetemp:=jo4.get('id').get_number;
								if j>1 then
							     v_spacecode:=v_spacecode||'_';
						    end if;
								v_spacecode:=v_spacecode||v_sapcetemp;
            --dbms_output.put_line(v_name);
            END LOOP;
            wx_aliasid := get_sequences('wx_alias');
            INSERT INTO wx_alias
                (id, ad_client_id, ad_org_id, wx_alias_code, wx_spec,
                 wx_specvalue, qty, pricelist, priceactual, weight, issale,lock_qty,
                 wx_appendgoods_id,wx_specid,creationdate,modifieddate,ownerid,modifierid)
                SELECT wx_aliasid, s.ad_client_id, s.ad_org_id, v_wx_alias_code,
                       TRIM('/' FROM v_spec), j3.to_char, v_qty, v_pricelist,
                       v_priceactual, v_weight, v_issale,v_lockqty, s.id,v_spacecode,sysdate,sysdate,s.ownerid,s.modifierid
                FROM wx_appendgoods s
                WHERE s.id = p_id;
        END LOOP;
    END IF;*/
END;

/
create or replace function wx_alias_$d_delete(f_user_id number,

                                              f_param   varchar2)
    return varchar2 is
    f_result_jo    json := new json();
    f_param_jo     json;
    f_space_code   varchar(100);
    f_tempalias_ja json_list;
		f_tempalias_clob clob;
		f_temp_jo        json:=new json();
		f_temp_clob       clob;
    f_ad_client_id number(10);
    f_count        number(10);
    f_appgood_id   number(10);
		f_default_qty  number(10);
		f_all_qty    number(10);
begin
    --raise_application_error(-20201,f_param);
    begin
        f_param_jo   := new json(f_param);
        f_space_code := f_param_jo.get('code').get_string;
        f_appgood_id := f_param_jo.get('id').get_number;
    exception
        when others then
            --f_appgood_id := 0;
            f_param_jo := new json();
            f_result_jo.put('code', -1);
            f_result_jo.put('message','找不到ID为：' || f_appgood_id || '的商品');
						f_temp_jo.put('code',-1);
						f_temp_jo.put('message','找不到ID为：' || f_appgood_id || '的商品');
						f_result_jo.put('data',f_temp_jo.to_char(false));
            return f_result_jo.to_char(false);
    end;
    if nvl(trim(f_space_code),null) is not null then
				select count(1)
				into   f_count
				from   wx_orderitem oi
				where oi.wx_alias_id in(select a.id
								from   wx_alias a
								where  a.wx_appendgoods_id = f_appgood_id and a.wx_specid=f_space_code);
		else
		    select count(1)
				into   f_count
				from   wx_orderitem oi
				where oi.wx_alias_id in(select a.id
								from   wx_alias a
								where  a.wx_appendgoods_id = f_appgood_id);
		end if;
    if f_count > 0 then
        f_param_jo := new json();
        f_result_jo.put('code', 0);
        f_result_jo.put('message', '该条码已生成订单，不能删除！');
				f_temp_jo.put('code',-1);
				f_temp_jo.put('message','该条码已生成订单，不能删除！');
				f_result_jo.put('data',f_temp_jo.to_char(false));
        return f_result_jo.to_char(false);
    end if;
    if nvl(trim(f_space_code),null) is not null then
       delete wx_alias a where a.wx_appendgoods_id=f_appgood_id and a.wx_specid = f_space_code;
		else
		   delete wx_alias a where a.wx_appendgoods_id=f_appgood_id;
		end if;
		--查询默认条码库存数量
		select nvl(sum(nvl(a.qty,0)),0)
		into f_default_qty
		from wx_alias a
		where a.wx_appendgoods_id=f_appgood_id
		and a.isdefault='Y';
		--查询所有条码库存
		select nvl(sum(nvl(a.qty,0)),0)
		into f_all_qty
		from wx_alias a
		where a.wx_appendgoods_id=f_appgood_id;
		--修改商品库存
		update wx_appendgoods ag set ag.remainnum=case when f_all_qty>f_default_qty then f_all_qty-f_default_qty else f_default_qty end
		where ag.id=f_appgood_id;
		--修改默认条码数量
		if f_all_qty=f_default_qty then
			update wx_alias a set(a.qty,a.pricelist,a.priceactual)
			                  =
						 (select ag.remainnum,ag.itemunitprice,ag.priceactual from wx_appendgoods ag where ag.id=f_appgood_id)
		  where a.wx_appendgoods_id=f_appgood_id
			and a.isdefault='Y';
		end if;
    --f_tempalias_ja:=json_dyn.executeList('select nvl(trim(a.wx_alias_code),'''') as "sku",nvl(trim(a.wx_specvalue),''[]'') as "space",nvl(trim(a.qty),0) as "inventory",nvl(trim(a.lock_qty),0) as "lockinventory",nvl(trim(a.priceactual),0) as "sellprice",nvl(trim(a.pricelist),0) as "costprice",nvl(trim(a.issale),''N'') as "putaway",nvl(trim(a.weight),0) as "wheight" from wx_alias a where a.wx_appendgoods_id='||f_appgood_id);
	  /*if f_tempalias_ja is null or f_tempalias_ja.count=0 then
		    f_result_jo.put('code',0);
				f_result_jo.put('message','操作成功!');
				f_result_jo.put('data','');
				return f_result_jo.to_char(false);
		end if;*/
		/*begin
		    select ag.spec_description
				into f_temp_clob
				from wx_appendgoods ag
				where ag.id=f_appgood_id;
		    f_temp_jo:=new json(f_temp_clob);
				f_temp_jo.put('child',f_tempalias_ja.to_json_value());
		exception when others then
		    f_temp_jo:=new json();
				f_temp_jo.put('keys',new json_list());
				f_temp_jo.put('child',f_tempalias_ja.to_json_value());
		end;
		f_tempalias_clob:=empty_clob();
		dbms_lob.createtemporary(f_tempalias_clob, true);
		--f_tempalias_jo.to_clob(f_tempalias_clob,true);
		f_temp_jo.to_clob(f_tempalias_clob,true);
		update wx_appendgoods ag set ag.spec_description=f_tempalias_clob where ag.id=f_appgood_id;*/
		f_result_jo.put('code',0);
		f_result_jo.put('message','操作成功!');
		f_temp_jo.put('code',0);
		f_temp_jo.put('message','操作成功!');
		f_result_jo.put('data',f_temp_jo.to_char(false));
		--f_result_jo.put('data',f_temp_jo);
    return f_result_jo.to_char(false);
end;

/
create or replace function wx_alias_$w_modifyorcreate(f_user_id in number,

                                                      f_param in clob)
    return varchar2 is
		f_result_clob  clob;
    f_param_jo     json;
    f_space_ja     json_list;
    f_alias_jo     json;
    f_tempspace_ja json_list;
		f_result_jo    json:=new json();
		f_temp_jo      json:=new json();
    f_sku        varchar2(1000);
    f_count      number(10);
    f_operate    varchar2(100);
    f_space      varchar2(500);
    f_space_code varchar2(500);
		f_adclientid number(10);
		f_wx_appgood_id number(10);
		f_wx_alias_id   number(10);
		f_default_qty  number(10);
		f_all_qty    number(10);
		f_all_count  number(10);
		f_sale_count number(10);
begin
    select u.ad_client_id
		into f_adclientid
		from users u
		where u.id=f_user_id;
    begin
        f_param_jo := json(f_param);
				f_wx_appgood_id:=f_param_jo.get('productid').get_number;
        f_space_ja := json_ext.get_json_list(f_param_jo,'child');
    exception
        when others then
            f_param_jo := new json();
            f_space_ja := new json_list();
						f_result_jo.put('code',0);
						f_result_jo.put('message','参数错误');
						f_temp_jo.put('code',-1);
						f_temp_jo.put('message','参数错误');
						f_result_jo.put('data',f_temp_jo.to_char(false));
						return f_result_jo.to_char(false);
    end;
    for i in 1 .. f_space_ja.count loop
        f_alias_jo := json(f_space_ja.get_elem(i));
        f_operate  := f_alias_jo.get('operate').get_string;
        begin
            f_tempspace_ja := json_ext.get_json_list(f_alias_jo, 'space');
            f_space        := f_tempspace_ja.to_char(false);
        exception
            when others then
                f_space := null;
        end;
        if f_operate = 'create' then
				    f_wx_alias_id:=get_sequences('wx_alias');
            insert into wx_alias
                (id,
                 ad_client_id,
                 ad_org_id,
                 wx_alias_code,
                 wx_spec,
                 wx_specvalue,
                 qty,
                 pricelist,
                 priceactual,
                 weight,
                 issale,
                 lock_qty,
                 wx_appendgoods_id,
                 wx_specid,
                 creationdate,
                 modifieddate,
                 ownerid,
                 modifierid,
                 isdefault)
                select f_wx_alias_id,
                       s.ad_client_id,
                       s.ad_org_id,
                       f_alias_jo.get('sku').get_string,
                       f_alias_jo.get('aliasname').get_string,
                       f_space,
                       f_alias_jo.get('inventory').get_number,
                       f_alias_jo.get('costprice').get_number,
                       f_alias_jo.get('sellprice').get_number,
                       f_alias_jo.get('wheight').get_number,
                       f_alias_jo.get('putaway').get_string,
                       f_alias_jo.get('lockinventory').get_number,
                       s.id,
                       f_alias_jo.get('aliascode').get_string,
                       sysdate,
                       sysdate,
                       s.ownerid,
                       s.modifierid,
                       'N'
                from   wx_appendgoods s
                where  s.id = f_wx_appgood_id;
						json_ext.put(f_param_jo,'child['||i||'].id',f_wx_alias_id);
        elsif f_operate = 'modify' then
            --判断条码是否被订单引用，若被引用，则不能修改
            select count(1)
            into   f_count
            from   wx_orderitem oi
            where  oi.wx_alias_id in
                   (select a.id
                    from   wx_alias a
                    where  a.id = f_alias_jo.get('id').get_number
                    and    a.wx_specid <> f_alias_jo.get('aliascode').get_string);
            if f_count > 0 then
						    f_result_jo.put('code',0);
								f_result_jo.put('message','商品条码：' || f_alias_jo.get('aliasname').get_string || '已被订单引用，不能修改。');
								f_temp_jo.put('code',-1);
								f_temp_jo.put('message','商品条码：' || f_alias_jo.get('aliasname').get_string || '已被订单引用，不能修改。');
								f_result_jo.put('data',f_temp_jo.to_char(false));
								return f_result_jo.to_char(false);
                --raise_application_error(-20201,'商品条码：' || f_alias_jo.get('aliasname').get_string || '已被订单引用，不能修改。');
            end if;
						--如果条码SKU不为空，则判断是否唯一
						f_sku:=f_alias_jo.get('sku').get_string;
						if nvl(f_sku,null) is not null then
						   select count(1)
							 into f_count
							 from wx_alias a where a.wx_alias_code=f_sku and a.id <> f_alias_jo.get('id').get_number and a.ad_client_id=f_adclientid;
						   if f_count>0 then
							    f_result_jo.put('code',0);
									f_result_jo.put('message','商品条码：' || f_alias_jo.get('aliasname').get_string || '，此货号已存在(可以设置为空)。');
									f_temp_jo.put('code',-1);
									f_temp_jo.put('message','商品条码：' || f_alias_jo.get('aliasname').get_string || '，此货号已存在(可以设置为空)。');
									f_result_jo.put('data',f_temp_jo.to_char(false));
									return f_result_jo.to_char(false);
							    --raise_application_error(-20201,'商品条码：' || f_alias_jo.get('aliasname').get_string || '维护了货号(可以设置为空)，此货号已存在。');
							 end if;
						end if;
						update wx_alias a
            set    a.wx_alias_code = f_alias_jo.get('sku').get_string,
                   a.wx_specvalue  = f_space,
                   a.wx_spec       = f_alias_jo.get('aliasname').get_string,
                   a.qty           = f_alias_jo.get('inventory').get_number,
                   a.lock_qty      = f_alias_jo.get('lockinventory').get_number,
                   a.priceactual   = f_alias_jo.get('sellprice').get_number,
                   a.pricelist     = f_alias_jo.get('costprice').get_number,
                   a.weight        = f_alias_jo.get('wheight').get_number,
                   a.issale        = f_alias_jo.get('putaway').get_string,
                   a.wx_specid     = f_alias_jo.get('aliascode').get_string,
                   a.modifieddate  = sysdate
            where  a.id = f_alias_jo.get('id').get_number;
        /*elsif f_operate = 'delete' then
            --判断条码是否被订单引用，若被引用，则不能删除
            select count(1)
            into   f_count
            from   wx_orderitem oi
            where  oi.wx_alias_id in
                   (select a.id
                    from   wx_alias a
                    where  a.id = f_alias_jo.get('id').get_number);
            if f_count > 0 then
                raise_application_error(-20201, '商品条码：【' || f_alias_jo.get('aliasname').get_string || '】已被订单引用，不能删除。');
            end if;
            delete wx_alias a where a.id = f_alias_jo.get('id').get_number;*/
        end if;
				json_ext.put(f_param_jo,'child['||i||'].operate','original');
    end loop;
		--查询默认条码库存数量
		select nvl(sum(nvl(a.qty,0)),0)
		into f_default_qty
		from wx_alias a
		where a.wx_appendgoods_id=f_wx_appgood_id
		and a.isdefault='Y';
		--查询所有条码库存
		select nvl(sum(nvl(a.qty,0)),0),count(1)
		into f_all_qty,f_all_count
		from wx_alias a
		where a.wx_appendgoods_id=f_wx_appgood_id
		and a.isdefault='N';
		select count(1)
		into f_sale_count
		from wx_alias a
		where a.wx_appendgoods_id=f_wx_appgood_id
		and a.isdefault='N'
		and a.issale='Y';
		--修改商品库存
		update wx_appendgoods ag set ag.remainnum=case when f_all_count>0 then f_all_qty else f_default_qty end,
		                             ag.itemstatus=case when f_sale_count>0 then 'Y' else ag.itemstatus end
		where ag.id=f_wx_appgood_id;
		--修改默认条码数量
		if f_all_count=0 then
			update wx_alias a set(a.qty,a.pricelist,a.priceactual)
			                  =
						 (select ag.remainnum,ag.itemunitprice,ag.priceactual from wx_appendgoods ag where ag.id=f_wx_appgood_id)
		  where a.wx_appendgoods_id=f_wx_appgood_id
			and a.isdefault='Y';
		end if;
		f_result_jo.put('code',0);
		f_result_jo.put('message','操作成功');
		f_temp_jo.put('code',0);
		f_temp_jo.put('message','操作成功');
		--f_temp_jo.put('data',f_param_jo);
		f_result_jo.put('data',f_temp_jo.to_char(false));
		/*
		f_result_clob:=empty_clob();
		dbms_lob.createtemporary(f_result_clob,true);
		f_result_jo.to_clob(f_result_clob,true);*/
		return f_result_jo.to_char(false);
end;

/
create or replace procedure wx_logistics_free(p_user_id in number,

                                                p_query   in varchar2,
                                                r_code    out number,
                                                r_message out varchar2) as
    f_codecount      number(10);
    f_address_id     number(10);
    f_logistics_id   number(10);
		f_ad_client_id   number(10);
    f_temp_xml       varchar2(1000);
    f_xml            xmltype;
begin
    r_code         := 0;
    r_message      := '0';
    f_temp_xml:='<data>'||p_query||'</data>';
    f_xml  := xmltype(f_temp_xml);
    SELECT extractvalue(VALUE(t), '/data/addressid'),extractvalue(VALUE(t), '/data/companyid')
    INTO f_address_id,f_ad_client_id
    FROM TABLE(XMLSEQUENCE(EXTRACT(f_xml, '/data'))) t;
    select count(1)
    into   f_codecount
    from   wx_logisticscost lc, wx_address wa, c_province cp, c_city cc
    where  wa.id = f_address_id
    and    lc.c_province_id=cp.id
		and    lc.c_city_id=cc.id
		and    lc.ad_client_id=f_ad_client_id
    and    wa.province = cp.name
    and    wa.city = cc.name;
    if f_codecount = 0 then
        select count(1)
        into   f_codecount
        from   wx_logisticscost lc, wx_address wa, c_province cp
        where  wa.id = f_address_id
        and    lc.c_province_id=cp.id
				and    lc.ad_client_id=f_ad_client_id
        and    wa.province = cp.name;
        if f_codecount > 0 then
            select nvl(lc.cost, 0)
            into   r_message
            from   wx_logisticscost lc, wx_address wa, c_province cp
            where  wa.id = f_address_id
            and    lc.c_province_id = cp.id
						and    lc.ad_client_id=f_ad_client_id
            and    wa.province = cp.name
            and    rownum=1;
        end if;
    else
        select nvl(lc.cost, 0)
        into   r_message
        from   wx_logisticscost lc, wx_address wa, c_province cp, c_city cc
        where  wa.id = f_address_id
        and    lc.c_province_id = cp.id
        and    lc.c_city_id = cc.id
				and    lc.ad_client_id=f_ad_client_id
        and    wa.province = cp.name
        and    wa.city = cc.name
        and    rownum=1;
    end if;
end;

/
create or replace PROCEDURE wx_order_acm(p_id IN NUMBER) AS

    -------------------------------------------------------------------------
    --add by zwm 20140402
    --1 如果是特殊活动类型单据，必须填写对应的销售活动
    --2 刷新团购单明细数据
    --3 更新单据状态为待支付，提交之后为已支付
    -------------------------------------------------------------------------
    v_groupon_id NUMBER(10);
    v_userid     NUMBER(10);
    v_order_id   NUMBER(10);
    v_ordertype  CHAR(3);
		v_couponemploy_id  number(10);
		v_coupon_money          number(10,2):=0;
		v_isUseCoupon   char(1):='N';
		v_isOverdue     char(1):='N';--是否过期
		v_coupon_id  NUMBER(10);
		v_coupon_count number(10);
		v_client_id     number(10);
    v_address varchar(250); --订单收货地址
    v_address_id number(10);--订单收货外键
BEGIN
    SELECT a.ad_client_id,a.wx_groupon_id, a.ordertype, a.id, a.ownerid,nvl(a.wx_couponemploy_id,0),decode(nvl(a.wx_couponemploy_id,0),0,'N','Y'),a.address,a.wx_address_id
    INTO v_client_id,v_groupon_id, v_ordertype, v_order_id, v_userid,v_couponemploy_id,v_isUseCoupon,v_address,v_address_id
    FROM wx_order a
    WHERE a.id = p_id;
    --更新订单地址通过外键  如果订单已经填入地址，则不允许修改
    IF v_address is NULL THEN
	  update wx_order t set(t.province,t.city,t.regionid,t.address,t.name,t.phonenum) =
	         (select w.province,w.city,w.regionid,w.address,w.name,w.phonenum from wx_address w where w.id = v_address_id)
	          where t.id = p_id;
    END IF;
    IF v_ordertype = '2' AND v_groupon_id IS NULL THEN
        raise_application_error(-20014, '此单为特殊活动订单，请选择对应的销售活动');
    END IF;
		--判断券是否被其它订单引用
		if v_couponemploy_id>0 then
				select count(1)
				into v_coupon_count
				from wx_order o
				where nvl(o.wx_couponemploy_id,0)=v_couponemploy_id
				and o.id<>p_id
				and o.ad_client_id=v_client_id;
				if v_coupon_count>=1 then
					 raise_application_error(-20014, '优惠券已被其它订单引用，请重新选择');
				end if;
		end if;
		if v_ordertype='1' then
		   begin
					--判断优惠券是否已过期
					/*select case when to_number(to_char(g.starttime,'yyyymmdd'))<=v_currentDate and v_currentDate<= to_number(to_char(g.endtime,'yyyymmdd')) then 'N' else 'Y' end,to_number(nvl(g.value,'0'))
					into v_isOverdue,v_coupon_money
					from wx_coupon g join wx_couponemploy ce on ce.wx_coupon_id=g.id
					where ce.id=v_couponemploy_id;*/
					select to_number(nvl(g.value, '0')),'N',g.id
					into   v_coupon_money,v_isOverdue,v_coupon_id
					from   wx_coupon g, wx_couponemploy t
					where  g.id = t.wx_coupon_id
					and    sysdate between g.starttime and
								 decode(g.validay, null, g.endtime, t.creationdate + g.validay)
					and    t.id = v_couponemploy_id;
			exception when others then
			       v_coupon_id:=null;
						 v_couponemploy_id:=null;
						 v_isOverdue:='Y';
						 v_coupon_money:=0;
			end;
			/*if nvl(v_isOverdue,'N')='Y' then
				 raise_application_error(-20201,'优惠券已过期，不能使用！');
			end if;*/
			--如果优惠金额大于0时，更新订单总金额，同时把优惠券状态改为已使用
			--if nvl(v_coupon_money,0)>0 and nvl(v_isOverdue,'N')='N' then
					--更新总金额
					UPDATE wx_order s
					SET (s.tot_amt_actual, s.tot_amt_pricelist, s.tot_amt, s.tot_qty,s.wx_coupon_id,s.wx_couponemploy_id) =
							 (SELECT SUM(a.amt_priceactual), SUM(a.amt_pricelist),
											 greatest((SUM(a.amt_priceactual)+nvl(s.logistics_free,0)-nvl(v_coupon_money,0)),0), SUM(a.qty),v_coupon_id,v_couponemploy_id
								FROM wx_orderitem a
								WHERE a.wx_order_id = p_id)
					WHERE s.id = p_id;
					--修改优惠券状态
					--update wx_couponemploy cm set cm.state='Y' where cm.id=v_couponemploy_id;
			--end if;
    --刷新团购单明细数据
    elsiF v_groupon_id IS NOT NULL AND v_ordertype = '2' THEN
        INSERT INTO wx_orderitem
            (id, ad_client_id, ad_org_id, wx_order_id, wx_appendgoods_id, qty,
             size_name, color, pricelist, priceactual, amt_pricelist,
             amt_priceactual, discount, ownerid, modifierid, creationdate,
             modifieddate, isactive)
            SELECT get_sequences('wx_orderitem'), m.ad_client_id, m.ad_org_id,
                   v_order_id, m.wx_appendgoods_id, 0, NULL, NULL,
                   p.itemunitprice, 0, 0, 0, 0, v_userid, v_userid, SYSDATE,
                   SYSDATE, 'Y'
            FROM wx_groupon m, wx_appendgoods p
            WHERE m.id = v_groupon_id
            AND m.wx_appendgoods_id = p.id;
    elsif v_ordertype='3' then
		    UPDATE wx_order s
				SET (s.tot_amt_actual, s.tot_amt_pricelist, s.tot_amt, s.tot_qty,s.wx_coupon_id) =
						 (SELECT SUM(a.amt_priceactual), SUM(a.amt_pricelist),
										 SUM(a.amt_priceactual), SUM(a.qty),v_coupon_id
							FROM wx_orderitem a
							WHERE a.wx_order_id = p_id)
				WHERE s.id = p_id;
    END IF;
END;

/
create or replace PROCEDURE wx_order_cancel(p_user_id IN NUMBER,

                                           p_query   IN VARCHAR2,
                                           r_code    OUT NUMBER,
                                           r_message OUT VARCHAR2) AS
    TYPE t_queryobj IS RECORD(
        tableid NUMBER(10),
        query   VARCHAR2(32676),
        id      VARCHAR2(10));
    v_queryobj t_queryobj;
    TYPE t_selection IS TABLE OF NUMBER(10) INDEX BY BINARY_INTEGER;
    v_selection t_selection;
    st_xml      VARCHAR2(32676);
    v_xml       xmltype;
    p_id NUMBER(10);
		p_vip_id    number(10);
		p_couponemploy_id   number(10);
		p_ordertype         char(3);
		p_integral          number(10);
BEGIN
    -- 从p_query解析参数
    st_xml := '<data>' || p_query || '</data>';
    v_xml := xmltype(st_xml);
    SELECT extractvalue(VALUE(t), '/data/table'),
           extractvalue(VALUE(t), '/data/query'),
           extractvalue(VALUE(t), '/data/id')
    INTO v_queryobj
    FROM TABLE(xmlsequence(extract(v_xml, '/data'))) t;
    SELECT extractvalue(VALUE(t), '/selection') BULK COLLECT
    INTO v_selection
    FROM TABLE(xmlsequence(extract(v_xml, '/data/selection'))) t;
    p_id := v_queryobj.id;
    --更新单据状态
    UPDATE wx_order t
    SET t.sale_status = '6'
    WHERE t.id = p_id;
		select o.wx_vip_id,o.wx_couponemploy_id,o.ordertype,o.amt_integral
		into p_vip_id,p_couponemploy_id,p_ordertype,p_integral
		from wx_order o
		where o.id=p_id;
		--还原会员积分
		if p_ordertype='3' then
		   update wx_vip v set v.integral=nvl（v.integral,0)+nvl(p_integral,0) where v.id=p_vip_id;
		end if;
		--如果有使用优惠券，则还原券为未使用状态
		--update wx_couponemploy ce set ce.state='N' where ce.id=nvl(p_couponemploy_id,0);
END;

/
create or replace PROCEDURE wx_order_cancel(p_user_id IN NUMBER,

                                           p_query   IN VARCHAR2,
                                           r_code    OUT NUMBER,
                                           r_message OUT VARCHAR2) AS
    TYPE t_queryobj IS RECORD(
        tableid NUMBER(10),
        query   VARCHAR2(32676),
        id      VARCHAR2(10));
    v_queryobj t_queryobj;
    TYPE t_selection IS TABLE OF NUMBER(10) INDEX BY BINARY_INTEGER;
    v_selection t_selection;
    st_xml      VARCHAR2(32676);
    v_xml       xmltype;
    p_id NUMBER(10);
		p_vip_id    number(10);
		p_couponemploy_id   number(10);
		p_ordertype         char(3);
		p_integral          number(10);
BEGIN
    -- 从p_query解析参数
    st_xml := '<data>' || p_query || '</data>';
    v_xml := xmltype(st_xml);
    SELECT extractvalue(VALUE(t), '/data/table'),
           extractvalue(VALUE(t), '/data/query'),
           extractvalue(VALUE(t), '/data/id')
    INTO v_queryobj
    FROM TABLE(xmlsequence(extract(v_xml, '/data'))) t;
    SELECT extractvalue(VALUE(t), '/selection') BULK COLLECT
    INTO v_selection
    FROM TABLE(xmlsequence(extract(v_xml, '/data/selection'))) t;
    p_id := v_queryobj.id;
    --更新单据状态
    UPDATE wx_order t
    SET t.sale_status = '6'
    WHERE t.id = p_id;
		select o.wx_vip_id,o.wx_couponemploy_id,o.ordertype,o.amt_integral
		into p_vip_id,p_couponemploy_id,p_ordertype,p_integral
		from wx_order o
		where o.id=p_id;
		--还原会员积分
		if p_ordertype='3' then
		   update wx_vip v set v.integral=nvl（v.integral,0)+nvl(p_integral,0) where v.id=p_vip_id;
		end if;
		--如果有使用优惠券，则还原券为未使用状态
		--update wx_couponemploy ce set ce.state='N' where ce.id=nvl(p_couponemploy_id,0);
END;

/
create or replace procedure wx_order_destocking(p_ad_client_id in number,p_orderDocno varchar2)as

     type p_alias is record(
		   qty number(10),
			 lock_qty number(10)
		 );
     p_lose_count number(10);
     p_order_state number(10);
		 p_orderitem_ids varchar2(100);
		 TYPE mybrray1 IS TABLE OF p_alias;
     p_lock_alias mybrray1;
		 p_adclient_id   number(10);
		 p_id            number(10);
		 p_appgoods_id   number(10);
		 p_coupon_value  number(16,2);
		 p_coupon_id     number(10);
		 f_temp_clob     clob;
		 f_temp_jo        json;
		 f_tempalias_jo json_list;
		 f_tempalias_clob clob;
		 f_wx_couponenu_id number(10);
begin
     begin
				 select o.sale_status,o.ad_client_id,o.id,nvl(o.wx_couponemploy_id,0),nvl(c.value,0),c.id
				 into p_order_state,p_adclient_id,p_id,f_wx_couponenu_id,p_coupon_value,p_coupon_id
				 from wx_order o left join wx_coupon c on o.wx_coupon_id=c.id
				 where o.docno=p_orderDocno
				 and o.ad_client_id=p_ad_client_id
				 and o.sale_status=3
				 and o.isstock='N';
		 exception when others then
		     return;
		 end;
     if p_order_state=3 then
		    if f_wx_couponenu_id>0 then
						--如果其它订单引用了和此单相同的优惠券，则让其它订单不使用优惠券。
						UPDATE wx_order s
						      SET (s.tot_amt_actual, s.tot_amt_pricelist, s.tot_amt, s.tot_qty,s.wx_coupon_id,s.wx_couponemploy_id)
									 =
								 (SELECT SUM(a.amt_priceactual), SUM(a.amt_pricelist),
												 greatest((SUM(a.amt_priceactual)+nvl(s.logistics_free,0)-0),0), SUM(a.qty),null,null
									FROM wx_orderitem a
									WHERE a.wx_order_id = s.id)
						WHERE s.id <> p_id
						and s.ad_client_id=p_ad_client_id
						and s.wx_couponemploy_id=f_wx_couponenu_id;
				 end if;
		    --锁定要修改库存的条码记录
		    select a.qty,a.lock_qty BULK COLLECT
				into p_lock_alias
				from wx_alias a
				where a.id in(select oi.wx_alias_id from wx_orderitem oi where oi.wx_order_id=p_id)
				for update of a.qty,a.lock_qty;-- wait 60;
		    --判断库存是否足够
				/*select count(1)
				into p_lose_count
				from wx_alias a join wx_orderitem oi on a.id=oi.wx_alias_id and oi.wx_order_id=p_id
				where oi.wx_appendgoods_id=p_id
				and oi.qty>a.qty-nvl(a.lock_qty,0);
		    if p_lose_count>0 then
				   --rollback;
				   raise_application_error(-20201,'商品库存不足');
				end if;*/
				update wx_alias a set (a.qty)=
				       (select a.qty-oi.qty from wx_orderitem oi where oi.wx_alias_id=a.id and oi.wx_order_id=p_id)
				where a.id in(select oi.wx_alias_id from wx_orderitem oi where oi.wx_alias_id=a.id and oi.wx_order_id=p_id);
				--and a.ad_client_id=p_adclient_id;
				--commit;
				--修改优惠券状态
				update wx_couponemploy cm set cm.state='Y' where cm.id=f_wx_couponenu_id;
				--修改商品总数量
				for orderitems in(select oi.wx_appendgoods_id,sum(nvl(oi.qty,0)) as qty from wx_orderitem oi where oi.wx_order_id=p_id group by oi.wx_appendgoods_id) loop
				    update wx_appendgoods ag set ag.remainnum=nvl(ag.remainnum,0)-nvl(orderitems.qty,0)
						where ag.id=orderitems.wx_appendgoods_id;
				end loop;
				--修改订单扣减库存状态
				update wx_order t set t.isstock='Y',t.errmessage='商品库存扣减成功' where t.id=p_id;
		 end if;
end;

/
create or replace function wx_coupon_onlinecoupon(f_vipid in number)

return varchar2 is
    f_result_jo json:=new json();
		f_couponitem_count    number(10);
		f_counonitem_code     varchar2(100);
		f_coupon_id           number(10);
		f_issend              char(1);
begin
    select count(1)
		into f_couponitem_count
		from wx_couponemploy ce
		where ce.wx_vip_id=f_vipid;
		begin
				select NVL(vt.ISSEND,'N'),nvl(vt.lqtype,'')
				into f_issend,f_coupon_id
				from wx_vip vp LEFT JOIN wx_vipbaseset vt ON vp.viptype=vt.id LEFT JOIN WX_COUPON CP ON NVL(vt.LQTYPE,-1)=cp.id
				WHERE vp.id=f_vipid;
		exception when others then
		    f_result_jo.put('code',-1);
				f_result_jo.put('message','查询VIP会员类型异常:'||sqlerrm);
				return f_result_jo.to_char();
		end;
		f_counonitem_code:=f_vipid||DBMS_RANDOM.STRING('a', 1)||floor(dbms_random.VALUE(10000, 100000))||(f_couponitem_count+1);
		if f_issend='N' or f_coupon_id='' then
		    f_result_jo.put('code',-1);
				f_result_jo.put('message','设置不发券');
				return f_result_jo.to_char();
		end if;
		INSERT INTO WX_COUPONEMPLOY(ID,AD_CLIENT_ID,AD_ORG_ID,SNCODE,STATE,WX_VIP_ID,ISSUETYPE,WX_COUPON_ID,OWNERID,MODIFIERID,CREATIONDATE,MODIFIEDDATE,USENUM)
			 SELECT get_Sequences('WX_COUPONEMPLOY'),v.AD_CLIENT_ID,v.AD_ORG_ID,f_counonitem_code,'N',f_vipid,1,f_coupon_id,v.OWNERID,v.MODIFIERID,SYSDATE,SYSDATE,1 FROM wx_vip v
			 WHERE v.id=f_vipid;
		f_result_jo.put('code',0);
		f_result_jo.put('message','发券成功');
		return f_result_jo.to_char();
end;

/
create or replace PROCEDURE wx_pay_bd(p_id IN NUMBER) AS

    -------------------------------------------------------------------------
    --add by zwm 20140418
    --判断支付方式是否已被引用
    -------------------------------------------------------------------------
    v_count NUMBER(10);
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM wx_order s
    WHERE s.payment = p_id;
    IF v_count <> 0 THEN
        raise_application_error(-20014, '此支付方式已被订单引用，不可删除！');
    END IF;
		--判断是否有默认支付方式
		begin
				select count(1)
				into v_count
				from wx_pay p
				where p.ad_client_id=(select pp.ad_client_id from wx_pay pp where pp.id=p_id)
				and p.isdefault='Y';
		exception when others then
		    v_count:=0;
		end;
		--没有时修改一条记录为默认支付方式
		if v_count=0 then
		   update wx_pay p set p.isdefault='Y' where rownum=1;
	  end if;
END;

/
create or replace PROCEDURE wx_pay_acm(p_id IN NUMBER) AS

    -------------------------------------------------------------------------
    --add by zwm 20140418
    --判断支付方式是否已被引用
    -------------------------------------------------------------------------
    v_count NUMBER(10);
		v_isdefault varchar2(10);
		v_adclient_id number(10);
BEGIN
    --获取当前记录支付方式
		select nvl(p.isdefault,'N'),p.ad_client_id
		into v_isdefault,v_adclient_id
		from wx_pay p
		where p.id=p_id;
		--如果当前记录不是默认支付方式
		if v_isdefault='N' then
				--判断是否有默认支付方式
				begin
						select count(1)
						into v_count
						from wx_pay p
						where p.ad_client_id=v_adclient_id
						and p.isdefault='Y';
				exception when others then
						v_count:=0;
				end;
				--没有时修改一条记录为默认支付方式
				if v_count=0 then
					 update wx_pay p set p.isdefault='Y' where rownum=1;
				end if;
		else
		    --修改其它默认支付方式为非默认支付方式
				update wx_pay p set p.isdefault='N' where p.ad_client_id=v_adclient_id and p.id<>p_id;
		end if;
END;

/
create or replace FUNCTION wx_message_$r_reply(p_user_id IN NUMBER,

                                               p_query   IN VARCHAR2)
    RETURN CLOB IS
    --------------------------------------------------------------
    --ADD BY ZWM 20140415
    --匹配消息自动回复
    --------------------------------------------------------------
    st_xml VARCHAR2(32676);
    v_xml  xmltype;
    TYPE t_queryobj IS RECORD(
        fromusername VARCHAR2(200),
        tousername   VARCHAR2(200),
        msgtype      VARCHAR2(80),
        keywords     VARCHAR2(1500));
    v_queryobj t_queryobj;
    v_keywords     VARCHAR2(1500);
    v_fromusername VARCHAR2(200);
    v_tousername   VARCHAR2(200);
    v_type         VARCHAR2(80);
    v_mstype       VARCHAR2(80);
    v_medier_id    VARCHAR2(100);
    v_count        NUMBER(10);
    v_count1       NUMBER(10);
    v_client_id    NUMBER(10);
    v_count12      NUMBER(10);
    TYPE r_count IS TABLE OF NUMBER(10) INDEX BY BINARY_INTEGER;
    m_count r_count;
    jos          json;
    jos1         json;
    jos2         json;
    joslist      json_list := NEW json_list;
    joslist1     json_list := NEW json_list;
    joslist2     json_list := NEW json_list;
    contentstr   VARCHAR2(4000);
    v_fid        NUMBER(10);
    v_odreplace  VARCHAR2(4000);
    v_replace    VARCHAR2(4000);
    v_receive    VARCHAR2(4000);
    v_url        VARCHAR2(4000);
    v_url1       VARCHAR2(4000);
    v_content    VARCHAR2(4000);
    v_sr1        VARCHAR2(4000);
    v_sr2        VARCHAR2(4000);
    v_appid      VARCHAR2(100);
    v_publictype CHAR(1);
    v_domain     VARCHAR2(4000);
   -- pjo     json := NEW json();
    v_wx_messageauto wx_messageauto%ROWTYPE;
BEGIN
    --pjo.put('p_query',p_query);
    -- raise_application_error(-20014, 'test');
    -- 从p_query解析数据
    st_xml := p_query;
    v_xml := xmltype(st_xml);
    SELECT extractvalue(VALUE(t), '/xml/FromUserName'),
           extractvalue(VALUE(t), '/xml/ToUserName'),
           extractvalue(VALUE(t), '/xml/MsgType'),
           extractvalue(VALUE(t), '/xml/KeyWords')
    INTO v_queryobj
    FROM TABLE(xmlsequence(extract(v_xml, '/xml'))) t;
    v_keywords := v_queryobj.keywords;
    v_fromusername := v_queryobj.fromusername;
    v_tousername := v_queryobj.tousername;
    v_type := v_queryobj.msgtype;
    --raise_application_error(-20014, 'ad_client_id:' || p_user_id || p_query);
    IF v_type <> 'subscribe' THEN
        v_client_id := p_user_id;
        SELECT COUNT(*)
        INTO v_count12
        FROM wx_messageauto t
        WHERE t.pptype IN ('Y', 'N')
        AND t.ad_client_id = v_client_id
        AND t.nytype = 'Y'
        AND (t.keyword = v_keywords OR t.keyword LIKE '%' || v_keywords || '%');
        SELECT s.appid, s.publictype
        INTO v_appid, v_publictype
        FROM wx_interfaceset s
        WHERE s.ad_client_id = v_client_id;
        IF v_count12 <> 0 THEN
            SELECT COUNT(*)
            INTO v_count1
            FROM wx_messageauto t
            WHERE t.keyword = v_keywords
            AND t.pptype = 'Y'
            AND t.nytype = 'Y'
            AND t.ad_client_id = v_client_id;
            IF v_count1 <> 0 THEN
                SELECT *
                INTO v_wx_messageauto
                FROM wx_messageauto t
                WHERE t.keyword = v_keywords
                AND t.pptype = 'Y'
                AND t.nytype = 'Y'
                AND t.ad_client_id = v_client_id;
            ELSE
                SELECT *
                INTO v_wx_messageauto
                FROM wx_messageauto t
                WHERE t.keyword LIKE '%' || v_keywords || '%'
                AND t.pptype = 'N'
                AND t.nytype = 'Y'
                AND t.ad_client_id = v_client_id
                and rownum=1
                order by t.keyword;
            END IF;
                SELECT 'http://'||wc.domain
                INTO v_domain
                FROM web_client wc
                WHERE wc.ad_client_id = v_client_id;
                IF v_publictype = '4' THEN
                   v_sr1 := 'https://open.weixin.qq.com/connect/oauth2/authorize?appid=' ||
                             v_appid || '&redirect_uri=';
                   v_sr2 := '&response_type=code&scope=snsapi_base&state=1#wechat_redirect';
                ELSE
                   v_sr1:='';
                   v_sr2:='';
                END IF;
            IF v_wx_messageauto.msgtype = 1 THEN
                /* <xml>
                <ToUserName><![CDATA[toUser]]></ToUserName>
                <FromUserName><![CDATA[fromUser]]></FromUserName>
                <CreateTime>12345678</CreateTime>
                <MsgType><![CDATA[text]]></MsgType>
                <Content><![CDATA[你好]]></Content>
                </xml> */
                --jos := json(v_wx_messageauto.urlcontent);
                v_content := v_wx_messageauto.content;
                --joslist := json_ext.get_json_list(jos, 'list');
                IF v_wx_messageauto.urlcontent IS NOT NULL THEN
                   BEGIN
                       joslist := json_list(v_wx_messageauto.urlcontent);
                   EXCEPTION WHEN OTHERS THEN
                       joslist :=json_list();
                   END;
                    FOR v IN 1 .. joslist.count LOOP
                        jos1 := json(joslist.get_elem(v));
                        v_fid := jos1.get('fromid').get_number;
                        v_odreplace := jos1.get('oldreplace').get_string;
                        v_replace := jos1.get('replace').get_string;
                        v_receive := jos1.get('receive').get_string;
                        BEGIN
                          SELECT t.purl
                          INTO v_url
                          FROM wx_v_jumpurlpath t
                          WHERE t.id = v_fid+v_client_id and t.ad_client_id=v_client_id ;
                        EXCEPTION WHEN no_data_found THEN
                          v_url:='';
                          v_replace:='#';
                        END;
                        IF v_url IS NULL THEN
                            v_url1 := v_replace;
                        ELSE
                            v_url1 := v_sr1 ||case when v_publictype='4' then replace(apex_util.url_encode(REPLACE(v_domain || v_url, v_odreplace, v_replace)),'%2E','.') else REPLACE(v_domain || v_url, v_odreplace, v_replace) end|| v_sr2;
                        END IF;
                        contentstr := v_content;
                        v_content := REPLACE(contentstr, v_receive, v_url1);
                    END LOOP;
                END IF;
                v_mstype := 'text';
                SELECT xmlelement("xml",
                                   xmlelement("ToUserName",
                                               xmlcdata(v_fromusername) "XMLCData"),
                                   xmlelement("FromUserName",
                                               xmlcdata(v_tousername) "XMLCData"),
                                   xmlelement("CreateTime",
                                               to_char(SYSDATE, 'yyyymmddhhmiss')),
                                   xmlelement("MsgType",
                                               xmlcdata(v_mstype) "XMLCData"),
                                   xmlelement("Content",
                                               xmlcdata(v_content /*v_wx_messageauto.content*/)
                                                "XMLCData"))
                INTO v_xml
                FROM dual;
                -- raise_application_error(-20014, 'test');
            ELSIF v_wx_messageauto.msgtype = 2 THEN
                /* <xml>
                <ToUserName><![CDATA[toUser]]></ToUserName>
                <FromUserName><![CDATA[fromUser]]></FromUserName>
                <CreateTime>12345678</CreateTime>
                <MsgType><![CDATA[image]]></MsgType>
                <Image>
                <MediaId><![CDATA[media_id]]></MediaId>
                </Image>
                </xml>*/
                v_mstype := 'image';
                SELECT b.media_id
                INTO v_medier_id
                FROM wx_messageauto a, wx_media b
                WHERE a.id = v_wx_messageauto.id
                AND a.wx_media_id = b.id
                AND a.ad_client_id = b.ad_client_id
                AND a.ad_client_id = v_client_id;
                SELECT xmlelement("xml",
                                   xmlelement("ToUserName",
                                               xmlcdata(v_fromusername) "XMLCData"),
                                   xmlelement("FromUserName",
                                               xmlcdata(v_tousername) "XMLCData"),
                                   xmlelement("CreateTime", SYSDATE),
                                   xmlelement("MsgType",
                                               xmlcdata(v_mstype) "XMLCData"),
                                   xmlelement("Image",
                                               xmlelement("MediaId",
                                                           xmlcdata(v_medier_id)
                                                            "XMLCData")))
                INTO v_xml
                FROM dual;
                --raise_application_error(-20014, 'test');
            ELSIF v_wx_messageauto.msgtype = 3 THEN
                /*<xml>
                <ToUserName><![CDATA[toUser]]></ToUserName>
                <FromUserName><![CDATA[fromUser]]></FromUserName>
                <CreateTime>12345678</CreateTime>
                <MsgType><![CDATA[voice]]></MsgType>
                <Voice>
                <MediaId><![CDATA[media_id]]></MediaId>
                </Voice>
                </xml>*/
                v_mstype := 'voice';
                SELECT b.media_id
                INTO v_medier_id
                FROM wx_messageauto a, wx_media b
                WHERE a.id = v_wx_messageauto.id
                AND a.wx_media_id = b.id
                AND a.ad_client_id = b.ad_client_id
                AND a.ad_client_id = v_client_id;
                SELECT xmlelement("xml",
                                   xmlelement("ToUserName",
                                               xmlcdata(v_fromusername) "XMLCData"),
                                   xmlelement("FromUserName",
                                               xmlcdata(v_tousername) "XMLCData"),
                                   xmlelement("CreateTime",
                                               to_char(SYSDATE, 'yyyymmddhhmiss')),
                                   xmlelement("MsgType",
                                               xmlcdata(v_mstype) "XMLCData"),
                                   xmlelement("Voice",
                                               xmlelement("MediaId",
                                                           xmlcdata(v_medier_id)
                                                            "XMLCData")))
                INTO v_xml
                FROM dual;
                --raise_application_error(-20014, 'test');
            ELSIF v_wx_messageauto.msgtype = 4 THEN
                /*<xml>
                <ToUserName><![CDATA[toUser]]></ToUserName>
                <FromUserName><![CDATA[fromUser]]></FromUserName>
                <CreateTime>12345678</CreateTime>
                <MsgType><![CDATA[video]]></MsgType>
                <Video>
                <MediaId><![CDATA[media_id]]></MediaId>
                <Title><![CDATA[title]]></Title>
                <Description><![CDATA[description]]></Description>
                </Video>
                </xml>*/
                v_mstype := 'video';
                SELECT b.media_id
                INTO v_medier_id
                FROM wx_messageauto a, wx_media b
                WHERE a.id = v_wx_messageauto.id
                AND a.wx_media_id = b.id
                AND a.ad_client_id = b.ad_client_id
                AND a.ad_client_id = v_client_id;
                SELECT xmlelement("xml",
                                   xmlelement("ToUserName",
                                               xmlcdata(v_fromusername) "XMLCData"),
                                   xmlelement("FromUserName",
                                               xmlcdata(v_tousername) "XMLCData"),
                                   xmlelement("CreateTime",
                                               to_char(SYSDATE, 'yyyymmddhhmiss')),
                                   xmlelement("MsgType",
                                               xmlcdata(v_mstype) "XMLCData"),
                                   xmlelement("Video",
                                               xmlelement("MediaId",
                                                           xmlcdata(v_medier_id)
                                                            "XMLCData"),
                                   xmlelement("Title",
                                               xmlcdata(v_wx_messageauto.title)
                                                "XMLCData"),
                                   xmlelement("Description",
                                               xmlcdata(v_wx_messageauto.content)
                                                "XMLCData")))
                INTO v_xml
                FROM dual;
                --raise_application_error(-20014, 'test');
            ELSIF v_wx_messageauto.msgtype = 5 THEN
                /*<xml>
                <ToUserName><![CDATA[toUser]]></ToUserName>
                <FromUserName><![CDATA[fromUser]]></FromUserName>
                <CreateTime>12345678</CreateTime>
                <MsgType><![CDATA[music]]></MsgType>
                <Music>
                <Title><![CDATA[TITLE]]></Title>
                <Description><![CDATA[DESCRIPTION]]></Description>
                <MusicUrl><![CDATA[MUSIC_Url]]></MusicUrl>
                <HQMusicUrl><![CDATA[HQ_MUSIC_Url]]></HQMusicUrl>
                <ThumbMediaId><![CDATA[media_id]]></ThumbMediaId>
                </Music>
                </xml>*/
                v_mstype := 'music';
                SELECT b.media_id
                INTO v_medier_id
                FROM wx_messageauto a, wx_media b
                WHERE a.id = v_wx_messageauto.id
                AND a.wx_media_id = b.id
                AND a.ad_client_id = b.ad_client_id
                AND a.ad_client_id = v_client_id;
                SELECT xmlelement("xml",
                                   xmlelement("ToUserName",
                                               xmlcdata(nvl(v_fromusername, ' '))
                                                "XMLCData"),
                                   xmlelement("FromUserName",
                                               xmlcdata(v_tousername) "XMLCData"),
                                   xmlelement("CreateTime",
                                               to_char(SYSDATE, 'yyyymmddhhmiss')),
                                   xmlelement("MsgType",
                                               xmlcdata(v_mstype) "XMLCData"),
                                   xmlelement("Music",
                                               xmlelement("Title",
                                                           xmlcdata(v_wx_messageauto.title)
                                                            "XMLCData"),
                                               xmlelement("Description",
                                                           xmlcdata(v_wx_messageauto.url)
                                                           xmlcdata(v_wx_messageauto.content)
                                                            "XMLCData"),
                                               xmlelement("MusicUrl",
                                                            "XMLCData"),
                                               xmlelement("HQMusicUrl",
                                                           xmlcdata(v_wx_messageauto.hurl)
                                                            "XMLCData"),
                                               xmlelement("ThumbMediaId",
                                                           xmlcdata(v_medier_id)
                                                            "XMLCData")))
                INTO v_xml
                FROM dual;
                --raise_application_error(-20014, 'test');
            ELSIF v_wx_messageauto.msgtype = 6 THEN
                /*<xml>
                <ToUserName><![CDATA[toUser]]></ToUserName>
                <FromUserName><![CDATA[fromUser]]></FromUserName>
                <CreateTime>12345678</CreateTime>
                <MsgType><![CDATA[news]]></MsgType>
                <ArticleCount>2</ArticleCount>
                <Articles>
                <item>
                <Title><![CDATA[title1]]></Title>
                <Description><![CDATA[description1]]></Description>
                <PicUrl><![CDATA[picurl]]></PicUrl>
                <Url><![CDATA[url]]></Url>
                </item>
                <item>
                <Title><![CDATA[title]]></Title>
                <Description><![CDATA[description]]></Description>
                <PicUrl><![CDATA[picurl]]></PicUrl>
                <Url><![CDATA[url]]></Url>
                </item>
                </Articles>
                </xml> */
                --raise_application_error(-20014, v_wx_messageauto.count);
                v_mstype := 'news';
                SELECT xmlelement("xml",
                                   xmlelement("ToUserName",
                                               xmlcdata(nvl(v_fromusername, ' '))
                                                "XMLCData"),
                                   xmlelement("FromUserName",
                                               xmlcdata(nvl(v_tousername, ' '))
                                                "XMLCData"),
                                   xmlelement("CreateTime",
                                               to_char(SYSDATE, 'yyyymmddhhmiss')),
                                   xmlelement("MsgType",
                                               xmlcdata(v_mstype) "XMLCData"),
                                   xmlelement("ArticleCount",
                                               v_wx_messageauto.count),
                                   xmlelement("Articles"))
                INTO v_xml
                FROM dual;
                SELECT appendchildxml(v_xml, 'xml/Articles',
                                       xmlagg(xmlelement("item",
                                                          (xmlforest(xmlcdata(nvl(s.title,
                                                                                   ' ')) AS
                                                                      "Title",
                                                                      xmlcdata(nvl(s.content,
                                                                                    ' ')) AS
                                                                       "Description",
                                                                      xmlcdata(nvl(v_domain||s.url,' ')) AS
                                                                       "PicUrl",
                                                                      xmlcdata(CASE
                                                                                    WHEN vj.url IS NULL OR vj.url = '' THEN
                                                                                     CASE WHEN vj.id IS NULL THEN '#'
                                                                                     ELSE nvl(s.objid, ' ')
                                                                                     END
                                                                                    ELSE
                                                                                    v_sr1||case when v_publictype='4'
                                                                                                          then replace(apex_util.url_encode(replace(nvl(v_domain||vj.purl,''), '@ID@', nvl(s.objid, ' '))),'%2E','.')
                                                                                                          else replace(nvl(v_domain||vj.purl,''), '@ID@', nvl(s.objid, ' '))
                                                                                                     end
                                                                                         ||v_sr2
                                                                                END) AS
                                                                       "Url")))
                                               ORDER BY s.sort asc))
                INTO v_xml
                FROM wx_messageautoitem s LEFT JOIN wx_v_jumpurlpath vj ON vj.id = s.fromid+v_client_id
                WHERE s.groupid = v_wx_messageauto.groupid and s.ad_client_id=v_client_id and vj.ad_client_id=v_client_id order by s.sort asc;
                --raise_application_error(-20014, 'test');
            END IF;
        ELSE
            v_xml := xmltype(wx_message_$r_un(p_user_id, p_query));
        END IF;
    ELSE
        v_xml := xmltype(wx_message_$r_scan(p_user_id, p_query));
    END IF;
    RETURN v_xml.getclobval();
EXCEPTION
    WHEN OTHERS THEN
      RETURN '<xml>null</xml>';
       --  RETURN pjo.to_char;
END;

/
create or replace FUNCTION wx_message_$r_replyq(p_user_id IN NUMBER,

                                                p_query   IN VARCHAR2)
    RETURN CLOB IS
    --------------------------------------------------------------
    --ADD BY ZWM 20140516
    --匹配消息自动回复
    --------------------------------------------------------------
    st_xml VARCHAR2(32676);
    v_xml  xmltype;
    TYPE t_queryobj IS RECORD(
        fromusername VARCHAR2(200),
        tousername   VARCHAR2(200),
        msgtype      VARCHAR2(80),
        keywords     VARCHAR2(1500));
    v_queryobj t_queryobj;
    v_keywords     VARCHAR2(1500);
    v_fromusername VARCHAR2(200);
    v_tousername   VARCHAR2(200);
    v_type         VARCHAR2(80);
    v_mstype       VARCHAR2(80);
    v_medier_id    VARCHAR2(100);
    v_count        NUMBER(10);
    v_count1       NUMBER(10);
    v_client_id    NUMBER(10);
    v_count12      NUMBER(10);
    TYPE r_count IS TABLE OF NUMBER(10) INDEX BY BINARY_INTEGER;
    m_count r_count;
    jos          json;
    jos1         json;
    jos2         json;
    joslist      json_list := NEW json_list;
    joslist1     json_list := NEW json_list;
    joslist2     json_list := NEW json_list;
    contentstr   VARCHAR2(4000);
    v_fid        NUMBER(10);
    v_odreplace  VARCHAR2(4000);
    v_replace    VARCHAR2(4000);
    v_receive    VARCHAR2(4000);
    v_url        VARCHAR2(4000);
    v_url1       VARCHAR2(4000);
    v_content    VARCHAR2(4000);
    v_sr1        VARCHAR2(4000);
    v_sr2        VARCHAR2(4000);
    v_appid      VARCHAR2(100);
    v_publictype CHAR(1);
    v_domain     VARCHAR2(4000);
    v_wx_messageauto wx_messageautoq%ROWTYPE;
BEGIN
    -- 从p_query解析数据
    st_xml := p_query;
    v_xml := xmltype(st_xml);
    SELECT extractvalue(VALUE(t), '/xml/FromUserName'),
           extractvalue(VALUE(t), '/xml/ToUserName'),
           extractvalue(VALUE(t), '/xml/MsgType'),
           extractvalue(VALUE(t), '/xml/KeyWords')
    INTO v_queryobj
    FROM TABLE(xmlsequence(extract(v_xml, '/xml'))) t;
    v_keywords := v_queryobj.keywords;
    v_fromusername := v_queryobj.fromusername;
    v_tousername := v_queryobj.tousername;
    v_type := v_queryobj.msgtype;
    --raise_application_error(-20014, 'ad_client_id:' || p_user_id || p_query);
    v_client_id := p_user_id;
    SELECT COUNT(*)
    INTO v_count1
    FROM wx_messageautoq t
    WHERE t.keyword = v_keywords
    AND t.pptype = 'Y'
    AND t.nytype = 'Y'
    AND t.ad_client_id = v_client_id;
    IF v_count1 <> 0 THEN
        SELECT *
        INTO v_wx_messageauto
        FROM wx_messageautoq t
        WHERE t.keyword = v_keywords
        AND t.pptype = 'Y'
        AND t.nytype = 'Y'
        AND t.ad_client_id = v_client_id;
        SELECT s.appid, s.publictype
        INTO v_appid, v_publictype
        FROM wx_interfaceset s
        WHERE s.ad_client_id = v_client_id;
        SELECT 'http://'||wc.domain
        INTO v_domain
        FROM web_client wc
        WHERE wc.ad_client_id = v_client_id;
        IF v_publictype = '4' THEN
           v_sr1 := 'https://open.weixin.qq.com/connect/oauth2/authorize?appid=' ||
                     v_appid || '&redirect_uri=';
           v_sr2 := '&response_type=code&scope=snsapi_base&state=1#wechat_redirect';
        ELSE
           v_sr1:='';
           v_sr2:='';
        END IF;
        IF v_wx_messageauto.msgtype = 1 THEN
            /* <xml>
            <ToUserName><![CDATA[toUser]]></ToUserName>
            <FromUserName><![CDATA[fromUser]]></FromUserName>
            <CreateTime>12345678</CreateTime>
            <MsgType><![CDATA[text]]></MsgType>
            <Content><![CDATA[你好]]></Content>
            </xml> */
            --jos := json(v_wx_messageauto.urlcontent);
            v_content := v_wx_messageauto.content;
            --joslist := json_ext.get_json_list(jos, 'list');
            IF v_wx_messageauto.urlcontent IS NOT NULL THEN
                BEGIN
                   joslist := json_list(v_wx_messageauto.urlcontent);
                EXCEPTION WHEN OTHERS THEN
                   joslist :=json_list();
               END;
                FOR v IN 1 .. joslist.count LOOP
                    jos1 := json(joslist.get_elem(v));
                    v_fid := jos1.get('fromid').get_number;
                    v_odreplace := jos1.get('oldreplace').get_string;
                    v_replace := jos1.get('replace').get_string;
                    v_receive := jos1.get('receive').get_string;
                    BEGIN
                      SELECT t.purl
                      INTO v_url
                      FROM wx_v_jumpurlpath t
                      WHERE t.id = v_fid+v_client_id and t.ad_client_id=v_client_id;
                    EXCEPTION WHEN no_data_found THEN
                      v_url:=NULL;
                      v_replace:='#';
                    END;
                    IF v_url IS NULL THEN
                        v_url1 := v_replace;
                    ELSE
                        v_url1 := v_sr1 ||v_domain || REPLACE(v_url, v_odreplace, v_replace)|| v_sr2;
                    END IF;
                    contentstr := v_content;
                    v_content := REPLACE(contentstr, v_receive, v_url1);
                END LOOP;
            END IF;
            v_mstype := 'text';
            SELECT xmlelement("xml",
                               xmlelement("ToUserName",
                                           xmlcdata(v_fromusername) "XMLCData"),
                               xmlelement("FromUserName",
                                           xmlcdata(v_tousername) "XMLCData"),
                               xmlelement("CreateTime",
                                           to_char(SYSDATE, 'yyyymmddhhmiss')),
                               xmlelement("MsgType", xmlcdata(v_mstype) "XMLCData"),
                               xmlelement("Content",
                                           xmlcdata(v_content /*v_wx_messageauto.content*/)
                                            "XMLCData"))
            INTO v_xml
            FROM dual;
            -- raise_application_error(-20014, 'test');
        ELSIF v_wx_messageauto.msgtype = 2 THEN
            /* <xml>
            <ToUserName><![CDATA[toUser]]></ToUserName>
            <FromUserName><![CDATA[fromUser]]></FromUserName>
            <CreateTime>12345678</CreateTime>
            <MsgType><![CDATA[image]]></MsgType>
            <Image>
            <MediaId><![CDATA[media_id]]></MediaId>
            </Image>
            </xml>*/
            v_mstype := 'image';
            SELECT b.media_id
            INTO v_medier_id
            FROM wx_messageautoq a, wx_media b
            WHERE a.id = v_wx_messageauto.id
            AND a.wx_media_id = b.id
            AND a.ad_client_id = b.ad_client_id
            AND a.ad_client_id = v_client_id;
            SELECT xmlelement("xml",
                               xmlelement("ToUserName",
                                           xmlcdata(v_fromusername) "XMLCData"),
                               xmlelement("FromUserName",
                                           xmlcdata(v_tousername) "XMLCData"),
                               xmlelement("CreateTime", SYSDATE),
                               xmlelement("MsgType", xmlcdata(v_mstype) "XMLCData"),
                               xmlelement("Image",
                                           xmlelement("MediaId",
                                                       xmlcdata(v_medier_id)
                                                        "XMLCData")))
            INTO v_xml
            FROM dual;
            --raise_application_error(-20014, 'test');
        ELSIF v_wx_messageauto.msgtype = 3 THEN
            /*<xml>
            <ToUserName><![CDATA[toUser]]></ToUserName>
            <FromUserName><![CDATA[fromUser]]></FromUserName>
            <CreateTime>12345678</CreateTime>
            <MsgType><![CDATA[voice]]></MsgType>
            <Voice>
            <MediaId><![CDATA[media_id]]></MediaId>
            </Voice>
            </xml>*/
            v_mstype := 'voice';
            SELECT b.media_id
            INTO v_medier_id
            FROM wx_messageautoq a, wx_media b
            WHERE a.id = v_wx_messageauto.id
            AND a.wx_media_id = b.id
            AND a.ad_client_id = b.ad_client_id
            AND a.ad_client_id = v_client_id;
            SELECT xmlelement("xml",
                               xmlelement("ToUserName",
                                           xmlcdata(v_fromusername) "XMLCData"),
                               xmlelement("FromUserName",
                                           xmlcdata(v_tousername) "XMLCData"),
                               xmlelement("CreateTime",
                                           to_char(SYSDATE, 'yyyymmddhhmiss')),
                               xmlelement("MsgType", xmlcdata(v_mstype) "XMLCData"),
                               xmlelement("Voice",
                                           xmlelement("MediaId",
                                                       xmlcdata(v_medier_id)
                                                        "XMLCData")))
            INTO v_xml
            FROM dual;
            --raise_application_error(-20014, 'test');
        ELSIF v_wx_messageauto.msgtype = 4 THEN
            /*<xml>
            <ToUserName><![CDATA[toUser]]></ToUserName>
            <FromUserName><![CDATA[fromUser]]></FromUserName>
            <CreateTime>12345678</CreateTime>
            <MsgType><![CDATA[video]]></MsgType>
            <Video>
            <MediaId><![CDATA[media_id]]></MediaId>
            <Title><![CDATA[title]]></Title>
            <Description><![CDATA[description]]></Description>
            </Video>
            </xml>*/
            v_mstype := 'video';
            SELECT b.media_id
            INTO v_medier_id
            FROM wx_messageautoq a, wx_media b
            WHERE a.id = v_wx_messageauto.id
            AND a.wx_media_id = b.id
            AND a.ad_client_id = b.ad_client_id
            AND a.ad_client_id = v_client_id;
            SELECT xmlelement("xml",
                               xmlelement("ToUserName",
                                           xmlcdata(v_fromusername) "XMLCData"),
                               xmlelement("FromUserName",
                                           xmlcdata(v_tousername) "XMLCData"),
                               xmlelement("CreateTime",
                                           to_char(SYSDATE, 'yyyymmddhhmiss')),
                               xmlelement("MsgType", xmlcdata(v_mstype) "XMLCData"),
                               xmlelement("Video",
                                           xmlelement("MediaId",
                                                       xmlcdata(v_medier_id)
                                                        "XMLCData"),
                               xmlelement("Title",
                                           xmlcdata(v_wx_messageauto.title)
                                            "XMLCData"),
                               xmlelement("Description",
                                           xmlcdata(v_wx_messageauto.content)
                                            "XMLCData")))
            INTO v_xml
            FROM dual;
            --raise_application_error(-20014, 'test');
        ELSIF v_wx_messageauto.msgtype = 5 THEN
            /*<xml>
            <ToUserName><![CDATA[toUser]]></ToUserName>
            <FromUserName><![CDATA[fromUser]]></FromUserName>
            <CreateTime>12345678</CreateTime>
            <MsgType><![CDATA[music]]></MsgType>
            <Music>
            <Title><![CDATA[TITLE]]></Title>
            <Description><![CDATA[DESCRIPTION]]></Description>
            <MusicUrl><![CDATA[MUSIC_Url]]></MusicUrl>
            <HQMusicUrl><![CDATA[HQ_MUSIC_Url]]></HQMusicUrl>
            <ThumbMediaId><![CDATA[media_id]]></ThumbMediaId>
            </Music>
            </xml>*/
            v_mstype := 'music';
            SELECT b.media_id
            INTO v_medier_id
            FROM wx_messageautoq a, wx_media b
            WHERE a.id = v_wx_messageauto.id
            AND a.wx_media_id = b.id
            AND a.ad_client_id = b.ad_client_id
            AND a.ad_client_id = v_client_id;
            SELECT xmlelement("xml",
                               xmlelement("ToUserName",
                                           xmlcdata(nvl(v_fromusername, ' '))
                                            "XMLCData"),
                               xmlelement("FromUserName",
                                           xmlcdata(v_tousername) "XMLCData"),
                               xmlelement("CreateTime",
                                           to_char(SYSDATE, 'yyyymmddhhmiss')),
                               xmlelement("MsgType", xmlcdata(v_mstype) "XMLCData"),
                               xmlelement("Music",
                                           xmlelement("Title",
                                                       xmlcdata(v_wx_messageauto.title)
                                                        "XMLCData"),
                                           xmlelement("Description",
                                                       xmlcdata(v_wx_messageauto.content)
                                                        "XMLCData"),
                                           xmlelement("MusicUrl",
                                                       xmlcdata(v_wx_messageauto.url)
                                                        "XMLCData"),
                                           xmlelement("HQMusicUrl",
                                                       xmlcdata(v_wx_messageauto.hurl)
                                                        "XMLCData"),
                                           xmlelement("ThumbMediaId",
                                                       xmlcdata(v_medier_id)
                                                        "XMLCData")))
            INTO v_xml
            FROM dual;
            --raise_application_error(-20014, 'test');
        ELSIF v_wx_messageauto.msgtype = 6 THEN
            /*<xml>
            <ToUserName><![CDATA[toUser]]></ToUserName>
            <FromUserName><![CDATA[fromUser]]></FromUserName>
            <CreateTime>12345678</CreateTime>
            <MsgType><![CDATA[news]]></MsgType>
            <ArticleCount>2</ArticleCount>
            <Articles>
            <item>
            <Title><![CDATA[title1]]></Title>
            <Description><![CDATA[description1]]></Description>
            <PicUrl><![CDATA[picurl]]></PicUrl>
            <Url><![CDATA[url]]></Url>
            </item>
            <item>
            <Title><![CDATA[title]]></Title>
            <Description><![CDATA[description]]></Description>
            <PicUrl><![CDATA[picurl]]></PicUrl>
            <Url><![CDATA[url]]></Url>
            </item>
            </Articles>
            </xml> */
            --raise_application_error(-20014, v_wx_messageauto.count);
            v_mstype := 'news';
            SELECT xmlelement("xml",
                               xmlelement("ToUserName",
                                           xmlcdata(nvl(v_tousername, ' '))
                                           xmlcdata(nvl(v_fromusername, ' '))
                                            "XMLCData"),
                               xmlelement("FromUserName",
                                            "XMLCData"),
                               xmlelement("CreateTime",
                                           to_char(SYSDATE, 'yyyymmddhhmiss')),
                               xmlelement("MsgType", xmlcdata(v_mstype) "XMLCData"),
                               xmlelement("ArticleCount", v_wx_messageauto.count),
                               xmlelement("Articles"))
            INTO v_xml
            FROM dual;
            SELECT appendchildxml(v_xml, 'xml/Articles',
                                   xmlagg(xmlelement("item",
                                                      (xmlforest(xmlcdata(nvl(s.title,
                                                                               ' ')) AS
                                                                  "Title",
                                                                  xmlcdata(nvl(s.content,
                                                                                ' ')) AS
                                                                   "Description",
                                                                  xmlcdata(nvl(v_domain||s.url,
                                                                                ' ')) AS
                                                                   "PicUrl",
                                                                  xmlcdata(CASE
                                                                                WHEN vj.url IS NULL OR vj.url = '' THEN
                                                                                 CASE WHEN vj.id is NULL THEN '#'
                                                                                 ELSE nvl(s.objid, ' ')
                                                                                 END
                                                                                ELSE
                                                                                v_sr1||case when v_publictype='4'
                                                                                                          then replace(apex_util.url_encode(replace(v_domain||nvl(vj.purl,''), '@ID@', nvl(s.objid, ' '))),'%2E','.')
                                                                                                          else replace(nvl(v_domain||vj.purl,''), '@ID@', nvl(s.objid, ' '))
                                                                                                     end
                                                                                         ||v_sr2
                                                                            END) AS
                                                                   "Url"))) ORDER BY
                                           s.sort asc))
            INTO v_xml
            FROM wx_messageautoitem s LEFT JOIN wx_v_jumpurlpath vj ON vj.id = s.fromid+v_client_id
            WHERE s.groupid = v_wx_messageauto.groupid and s.ad_client_id=v_client_id and vj.ad_client_id=v_client_id order by s.sort asc;
        END IF;
        --raise_application_error(-20014, 'test');
    END IF;
    RETURN v_xml.getclobval();
EXCEPTION
    WHEN OTHERS THEN
        RETURN '<xml>null</xml>';
END;

/
create or replace FUNCTION wx_message_$r_scan(p_user_id IN NUMBER,

                                              p_query   IN VARCHAR2)
    RETURN CLOB IS
    --------------------------------------------------------------
    --ADD BY ZWM 20140416
    --扫描自动回复信息
    --------------------------------------------------------------
    st_xml VARCHAR2(32676);
    v_xml  xmltype;
    v_xml1 xmltype;
    TYPE t_queryobj IS RECORD(
        fromusername VARCHAR2(200),
        tousername   VARCHAR2(200),
        msgtype      VARCHAR2(80),
        keywords     VARCHAR2(1500));
    v_queryobj t_queryobj;
    v_keywords     VARCHAR2(1500);
    v_fromusername VARCHAR2(200);
    v_tousername   VARCHAR2(200);
    v_type         VARCHAR2(80);
    v_medier_id    VARCHAR2(100);
    v_count        NUMBER(10);
    v_count1       NUMBER(10);
    v_client_id    NUMBER(10);
    jos          json;
    jos1         json;
    jos2         json;
    joslist      json_list := NEW json_list;
    joslist1     json_list := NEW json_list;
    joslist2     json_list := NEW json_list;
    contentstr   VARCHAR2(4000);
    v_fid        NUMBER(10);
    v_odreplace  VARCHAR2(4000);
    v_replace    VARCHAR2(4000);
    v_receive    VARCHAR2(4000);
    v_url        VARCHAR2(4000);
    v_url1       VARCHAR2(4000);
    v_content    VARCHAR2(4000);
    v_sr1        VARCHAR2(4000);
    v_sr2        VARCHAR2(4000);
    v_appid      VARCHAR2(100);
    v_publictype CHAR(1);
    v_domain     VARCHAR2(4000);
    v_wx_attentionsetscan wx_attentionset%ROWTYPE;
BEGIN
    -- 从p_query解析参数
    st_xml := p_query;
    v_xml := xmltype(st_xml);
    SELECT extractvalue(VALUE(t), '/xml/FromUserName'),
           extractvalue(VALUE(t), '/xml/ToUserName'),
           extractvalue(VALUE(t), '/xml/MsgType'),
           extractvalue(VALUE(t), '/xml/KeyWords')
    INTO v_queryobj
    FROM TABLE(xmlsequence(extract(v_xml, '/xml'))) t;
    v_keywords := v_queryobj.keywords;
    v_fromusername := v_queryobj.fromusername;
    v_tousername := v_queryobj.tousername;
    v_type := v_queryobj.msgtype;
    IF v_type = 'subscribe' THEN
        v_client_id := p_user_id;
        SELECT *
        INTO v_wx_attentionsetscan
        FROM wx_attentionset s
        WHERE s.dotype = 2
        AND s.nytype = 'Y'
        AND s.ad_client_id = v_client_id;
        SELECT s.appid, s.publictype
        INTO v_appid, v_publictype
        FROM wx_interfaceset s
        WHERE s.ad_client_id = v_client_id;
        SELECT 'http://'||wc.domain
        INTO v_domain
        FROM web_client wc
        WHERE wc.ad_client_id = v_client_id;
        IF v_publictype = '4' THEN
           v_sr1 := 'https://open.weixin.qq.com/connect/oauth2/authorize?appid=' ||
                     v_appid || '&redirect_uri=';
           v_sr2 := '&response_type=code&scope=snsapi_base&state=1#wechat_redirect';
        ELSE
           v_sr1:='';
           v_sr2:='';
        END IF;
        IF v_wx_attentionsetscan.msgtype = 1 THEN
            /* <xml>
            <ToUserName><![CDATA[toUser]]></ToUserName>
            <FromUserName><![CDATA[fromUser]]></FromUserName>
            <CreateTime>12345678</CreateTime>
            <MsgType><![CDATA[text]]></MsgType>
            <Content><![CDATA[你好]]></Content>
            </xml>*/
            --jos := json(v_wx_attentionsetscan.urlcontent);
            v_content := v_wx_attentionsetscan.content;
            IF v_wx_attentionsetscan.urlcontent IS NOT NULL THEN
                BEGIN
                     joslist := json_list(v_wx_attentionsetscan.urlcontent);
                 EXCEPTION WHEN OTHERS THEN
                     joslist :=json_list();
                 END;
                -- joslist := json_ext.get_json_list(jos, 'list');
                FOR v IN 1 .. joslist.count LOOP
                    jos1 := json(joslist.get_elem(v));
                    v_fid := jos1.get('fromid').get_number;
                    v_odreplace := jos1.get('oldreplace').get_string;
                    v_replace := jos1.get('replace').get_string;
                    v_receive := jos1.get('receive').get_string;
                    BEGIN
                      SELECT t.purl
                      INTO v_url
                      FROM wx_v_jumpurlpath t
                      WHERE t.id = v_fid+v_client_id and t.ad_client_id=v_client_id;
                    EXCEPTION WHEN no_data_found THEN
                      v_url:=NULL;
                      v_replace:='#';
                    END;
                    IF v_url IS NULL THEN
                        v_url1 := v_replace;
                    ELSE
                        v_url1 := v_sr1 ||case when v_publictype='4' then replace(apex_util.url_encode(REPLACE(v_domain ||v_url, v_odreplace, v_replace)),'%2E','.') else REPLACE(v_domain ||v_url, v_odreplace, v_replace) end|| v_sr2;
                    END IF;
                    contentstr := v_content;
                    v_content := REPLACE(contentstr, v_receive, v_url1);
                END LOOP;
            END IF;
            SELECT xmlelement("xml",
                               xmlelement("ToUserName",
                                           xmlcdata(v_fromusername) "XMLCData"),
                               xmlelement("FromUserName",
                                           xmlcdata(v_tousername) "XMLCData"),
                               xmlelement("CreateTime",
                                           to_char(SYSDATE, 'yyyymmddhhmiss')),
                               xmlelement("MsgType", xmlcdata('text') "XMLCData"),
                               xmlelement("Content",
                                           xmlcdata(v_content /*v_wx_attentionsetscan.content*/)
                                            "XMLCData"))
            INTO v_xml
            FROM dual;
            -- raise_application_error(-20014, 'test');
        ELSIF v_wx_attentionsetscan.msgtype = 2 THEN
            /* <xml>
            <ToUserName><![CDATA[toUser]]></ToUserName>
            <FromUserName><![CDATA[fromUser]]></FromUserName>
            <CreateTime>12345678</CreateTime>
            <MsgType><![CDATA[image]]></MsgType>
            <Image>
            <MediaId><![CDATA[media_id]]></MediaId>
            </Image>
            </xml>*/
            SELECT b.media_id
            INTO v_medier_id
            FROM wx_attentionset a, wx_media b
            WHERE a.id = v_wx_attentionsetscan.id
            AND a.wx_media_id = b.id
            AND a.ad_client_id = b.ad_client_id
            AND a.ad_client_id = v_client_id;
            SELECT xmlelement("xml",
                               xmlelement("ToUserName",
                                           xmlcdata(v_fromusername) "XMLCData"),
                               xmlelement("FromUserName",
                                           xmlcdata(v_tousername) "XMLCData"),
                               xmlelement("CreateTime",
                                           to_char(SYSDATE, 'yyyymmddhhmiss')),
                               xmlelement("MsgType", xmlcdata('image') "XMLCData"),
                               xmlelement("Image",
                                           xmlelement("MediaId",
                                                       xmlcdata(v_medier_id)
                                                        "XMLCData")))
            INTO v_xml
            FROM dual;
            --raise_application_error(-20014, 'test');
        ELSIF v_wx_attentionsetscan.msgtype = 3 THEN
            /*<xml>
            <ToUserName><![CDATA[toUser]]></ToUserName>
            <FromUserName><![CDATA[fromUser]]></FromUserName>
            <CreateTime>12345678</CreateTime>
            <MsgType><![CDATA[voice]]></MsgType>
            <Voice>
            <MediaId><![CDATA[media_id]]></MediaId>
            </Voice>
            </xml>*/
            SELECT b.media_id
            INTO v_medier_id
            FROM wx_attentionset a, wx_media b
            WHERE a.id = v_wx_attentionsetscan.id
            AND a.wx_media_id = b.id
            AND a.ad_client_id = b.ad_client_id
            AND a.ad_client_id = v_client_id;
            SELECT xmlelement("xml",
                               xmlelement("ToUserName",
                                           xmlcdata(v_fromusername) "XMLCData"),
                               xmlelement("FromUserName",
                                           xmlcdata(v_tousername) "XMLCData"),
                               xmlelement("CreateTime",
                                           to_char(SYSDATE, 'yyyymmddhhmiss')),
                               xmlelement("MsgType", xmlcdata('voice') "XMLCData"),
                               xmlelement("Voice",
                                           xmlelement("MediaId",
                                                       xmlcdata(v_medier_id)
                                                        "XMLCData")))
            INTO v_xml
            FROM dual;
            --raise_application_error(-20014, 'test');
        ELSIF v_wx_attentionsetscan.msgtype = 4 THEN
            /*<xml>
            <ToUserName><![CDATA[toUser]]></ToUserName>
            <FromUserName><![CDATA[fromUser]]></FromUserName>
            <CreateTime>12345678</CreateTime>
            <MsgType><![CDATA[video]]></MsgType>
            <Video>
            <MediaId><![CDATA[media_id]]></MediaId>
            <Title><![CDATA[title]]></Title>
            <Description><![CDATA[description]]></Description>
            </Video>
            </xml>*/
            SELECT b.media_id
            INTO v_medier_id
            FROM wx_attentionset a, wx_media b
            WHERE a.id = v_wx_attentionsetscan.id
            AND a.wx_media_id = b.id
            AND a.ad_client_id = b.ad_client_id
            AND a.ad_client_id = v_client_id;
            SELECT xmlelement("xml",
                               xmlelement("ToUserName",
                                           xmlcdata(v_fromusername) "XMLCData"),
                               xmlelement("FromUserName",
                                           xmlcdata(v_tousername) "XMLCData"),
                               xmlelement("CreateTime",
                                           to_char(SYSDATE, 'yyyymmddhhmiss')),
                               xmlelement("MsgType", xmlcdata('video') "XMLCData"),
                               xmlelement("Video",
                                           xmlelement("MediaId",
                                                       xmlcdata(v_medier_id)
                                                        "XMLCData"),
                               xmlelement("Title",
                                           xmlcdata(v_wx_attentionsetscan.title)
                                            "XMLCData"),
                               xmlelement("Description",
                                           xmlcdata(v_wx_attentionsetscan.content)
                                            "XMLCData")))
            INTO v_xml
            FROM dual;
            --raise_application_error(-20014, 'test');
        ELSIF v_wx_attentionsetscan.msgtype = 5 THEN
            /*<xml>
            <ToUserName><![CDATA[toUser]]></ToUserName>
            <FromUserName><![CDATA[fromUser]]></FromUserName>
            <CreateTime>12345678</CreateTime>
            <MsgType><![CDATA[music]]></MsgType>
            <Music>
            <Title><![CDATA[TITLE]]></Title>
            <Description><![CDATA[DESCRIPTION]]></Description>
            <MusicUrl><![CDATA[MUSIC_Url]]></MusicUrl>
            <HQMusicUrl><![CDATA[HQ_MUSIC_Url]]></HQMusicUrl>
            <ThumbMediaId><![CDATA[media_id]]></ThumbMediaId>
            </Music>
            </xml>*/
            SELECT b.media_id
            INTO v_medier_id
            FROM wx_attentionset a, wx_media b
            WHERE a.id = v_wx_attentionsetscan.id
            AND a.wx_media_id = b.id
            AND a.ad_client_id = b.ad_client_id
            AND a.ad_client_id = v_client_id;
            SELECT xmlelement("xml",
                               xmlelement("ToUserName",
                                           xmlcdata(v_fromusername) "XMLCData"),
                               xmlelement("FromUserName",
                                           xmlcdata(v_tousername) "XMLCData"),
                               xmlelement("CreateTime",
                                           to_char(SYSDATE, 'yyyymmddhhmiss')),
                               xmlelement("MsgType", xmlcdata('music') "XMLCData"),
                               xmlelement("Music",
                                           xmlelement("Title",
                                                       xmlcdata(v_wx_attentionsetscan.title)
                                                        "XMLCData"),
                                           xmlelement("Description",
                                                       xmlcdata(v_wx_attentionsetscan.content)
                                                        "XMLCData"),
                                           xmlelement("MusicUrl",
                                                       xmlcdata(v_wx_attentionsetscan.url)
                                                        "XMLCData"),
                                           xmlelement("HQMusicUrl",
                                                       xmlcdata(v_wx_attentionsetscan.hurl)
                                                        "XMLCData"),
                                           xmlelement("ThumbMediaId",
                                                       xmlcdata(v_medier_id)
                                                        "XMLCData")))
            INTO v_xml
            FROM dual;
            --raise_application_error(-20014, 'test');
        ELSIF v_wx_attentionsetscan.msgtype = 6 THEN
            /*<xml>
            <ToUserName><![CDATA[toUser]]></ToUserName>
            <FromUserName><![CDATA[fromUser]]></FromUserName>
            <CreateTime>12345678</CreateTime>
            <MsgType><![CDATA[news]]></MsgType>
            <ArticleCount>2</ArticleCount>
            <Articles>
            <item>
            <Title><![CDATA[title1]]></Title>
            <Description><![CDATA[description1]]></Description>
            <PicUrl><![CDATA[picurl]]></PicUrl>
            <Url><![CDATA[url]]></Url>
            </item>
            <item>
            <Title><![CDATA[title]]></Title>
            <Description><![CDATA[description]]></Description>
            <PicUrl><![CDATA[picurl]]></PicUrl>
            <Url><![CDATA[url]]></Url>
            </item>
            </Articles>
            </xml> */
            SELECT xmlelement("xml",
                               xmlelement("ToUserName",
                                           xmlcdata(v_fromusername) "XMLCData"),
                               xmlelement("FromUserName",
                                           xmlcdata(v_tousername) "XMLCData"),
                               xmlelement("CreateTime",
                                           to_char(SYSDATE, 'yyyymmddhhmiss')),
                               xmlelement("MsgType", xmlcdata('news') "XMLCData"),
                               xmlelement("ArticleCount",
                                           v_wx_attentionsetscan.count),
                               xmlelement("Articles"))
            INTO v_xml
            FROM dual;
            SELECT appendchildxml(v_xml, 'xml/Articles',
                                   xmlagg(xmlelement("item",
                                                      (xmlforest(xmlcdata(nvl(s.title,
                                                                               ' ')) AS
                                                                  "Title",
                                                                  xmlcdata(nvl(s.content,
                                                                                ' ')) AS
                                                                   "Description",
                                                                  xmlcdata(nvl(v_domain||s.url,' ')) AS
                                                                   "PicUrl",
                                                                  xmlcdata(CASE
                                                                                WHEN vj.url IS NULL OR vj.url = '' THEN
                                                                                 CASE WHEN vj.ID is NULL THEN '#'
                                                                                 ELSE nvl(s.objid, ' ')
                                                                                 END
                                                                                ELSE
                                                                                v_sr1||case when v_publictype='4'
                                                                                                          then replace(apex_util.url_encode(replace(nvl(v_domain||vj.purl,''), '@ID@', nvl(s.objid, ' '))),'%2E','.')
                                                                                                          else replace(nvl(v_domain||vj.purl,''), '@ID@', nvl(s.objid, ' '))
                                                                                                     end
                                                                                         ||v_sr2
                                                                            END) AS
                                                                   "Url"))) ORDER BY
                                           s.sort asc))
            INTO v_xml
            FROM wx_attentionsetitem s LEFT JOIN wx_v_jumpurlpath vj ON vj.id = s.fromid+v_client_id
            WHERE s.wx_attentionset_id = v_wx_attentionsetscan.id and s.ad_client_id=v_client_id and vj.ad_client_id=v_client_id order by s.sort asc;
            --raise_application_error(-20014, 'test');
        END IF;
    END IF;
    RETURN v_xml.getclobval();
EXCEPTION
    WHEN OTHERS THEN
        RETURN '<xml>null</xml>';
END;

/
create or replace FUNCTION wx_message_$r_un(p_user_id IN NUMBER,

                                            p_query   IN VARCHAR2) RETURN CLOB IS
    --------------------------------------------------------------
    --ADD BY ZWM 20140416
    --扫描自动回复信息
    --------------------------------------------------------------
    st_xml VARCHAR2(32676);
    v_xml  xmltype;
    v_xml1 xmltype;
    TYPE t_queryobj IS RECORD(
        fromusername VARCHAR2(200),
        tousername   VARCHAR2(200),
        msgtype      VARCHAR2(80),
        keywords     VARCHAR2(1500));
    v_queryobj t_queryobj;
    v_keywords     VARCHAR2(1500);
    v_fromusername VARCHAR2(200);
    v_tousername   VARCHAR2(200);
    v_type         VARCHAR2(80);
    v_medier_id    VARCHAR2(100);
    v_count        NUMBER(10);
    v_count1       NUMBER(10);
    v_client_id    NUMBER(10);
    jos          json;
    jos1         json;
    jos2         json;
    joslist      json_list := NEW json_list;
    joslist1     json_list := NEW json_list;
    joslist2     json_list := NEW json_list;
    contentstr   VARCHAR2(4000);
    v_fid        NUMBER(10);
    v_odreplace  VARCHAR2(4000);
    v_replace    VARCHAR2(4000);
    v_receive    VARCHAR2(4000);
    v_url        VARCHAR2(4000);
    v_url1       VARCHAR2(4000);
    v_content    VARCHAR2(4000);
    v_sr1        VARCHAR2(4000);
    v_sr2        VARCHAR2(4000);
    v_appid      VARCHAR2(100);
    v_publictype CHAR(1);
    v_domain     VARCHAR2(4000);
    v_wx_attentionsetscan wx_attentionset%ROWTYPE;
BEGIN
    -- 从p_query解析参数
    st_xml := p_query;
    v_xml := xmltype(st_xml);
    SELECT extractvalue(VALUE(t), '/xml/FromUserName'),
           extractvalue(VALUE(t), '/xml/ToUserName'),
           extractvalue(VALUE(t), '/xml/MsgType'),
           extractvalue(VALUE(t), '/xml/KeyWords')
    INTO v_queryobj
    FROM TABLE(xmlsequence(extract(v_xml, '/xml'))) t;
    v_keywords := v_queryobj.keywords;
    v_fromusername := v_queryobj.fromusername;
    v_tousername := v_queryobj.tousername;
    v_type := v_queryobj.msgtype;
    IF v_type <> 'subscribe' THEN
        v_client_id := p_user_id;
        SELECT *
        INTO v_wx_attentionsetscan
        FROM wx_attentionset s
        WHERE s.dotype = 1
        AND s.nytype = 'Y'
        AND s.ad_client_id = v_client_id;
        SELECT s.appid, s.publictype
        INTO v_appid, v_publictype
        FROM wx_interfaceset s
        WHERE s.ad_client_id = v_client_id;
        SELECT 'http://'||wc.domain
        INTO v_domain
        FROM web_client wc
        WHERE wc.ad_client_id = v_client_id;
        IF v_publictype = '4' THEN
           v_sr1 := 'https://open.weixin.qq.com/connect/oauth2/authorize?appid=' ||
                     v_appid || '&redirect_uri=';
           v_sr2 := '&response_type=code&scope=snsapi_base&state=1#wechat_redirect';
        ELSE
           v_sr1:='';
           v_sr2:='';
        END IF;
        IF v_wx_attentionsetscan.msgtype = 1 THEN
            /* <xml>
            <ToUserName><![CDATA[toUser]]></ToUserName>
            <FromUserName><![CDATA[fromUser]]></FromUserName>
            <CreateTime>12345678</CreateTime>
            <MsgType><![CDATA[text]]></MsgType>
            <Content><![CDATA[你好]]></Content>
            </xml>*/
            -- jos := json(v_wx_attentionsetscan.urlcontent);
            v_content := v_wx_attentionsetscan.content;
            IF v_wx_attentionsetscan.urlcontent IS NOT NULL THEN
               BEGIN
                   joslist := json_list(v_wx_attentionsetscan.urlcontent);
               EXCEPTION WHEN OTHERS THEN
                   joslist :=json_list();
               END;
                -- joslist := json_ext.get_json_list(jos, 'list');
                FOR v IN 1 .. joslist.count LOOP
                    jos1 := json(joslist.get_elem(v));
                    v_fid := jos1.get('fromid').get_number;
                    v_odreplace := jos1.get('oldreplace').get_string;
                    v_replace := jos1.get('replace').get_string;
                    v_receive := jos1.get('receive').get_string;
                    BEGIN
                      SELECT t.purl
                      INTO v_url
                      FROM wx_v_jumpurlpath t
                      WHERE t.id = v_fid+v_client_id and t.ad_client_id=v_client_id;
                    EXCEPTION WHEN no_data_found THEN
                       v_url:=NULL;
                       v_replace:='#';
                    END;
                    IF v_url IS NULL THEN
                        v_url1 := v_replace;
                    ELSE
                        v_url1 :=  v_sr1 ||case when v_publictype='4' then replace(apex_util.url_encode(REPLACE( v_domain ||v_url, v_odreplace, v_replace)),'%2E','.') else REPLACE( v_domain ||v_url, v_odreplace, v_replace) end || v_sr2;
                    END IF;
                    contentstr := v_content;
                    v_content := REPLACE(contentstr, v_receive, v_url1);
                END LOOP;
            END IF;
            SELECT xmlelement("xml",
                               xmlelement("ToUserName",
                                           xmlcdata(v_fromusername) "XMLCData"),
                               xmlelement("FromUserName",
                                           xmlcdata(v_tousername) "XMLCData"),
                               xmlelement("CreateTime",
                                           to_char(SYSDATE, 'yyyymmddhhmiss')),
                               xmlelement("MsgType", xmlcdata('text') "XMLCData"),
                               xmlelement("Content",
                                           xmlcdata(v_content /*v_wx_attentionsetscan.content*/)
                                            "XMLCData"))
            INTO v_xml
            FROM dual;
            -- raise_application_error(-20014, 'test');
        ELSIF v_wx_attentionsetscan.msgtype = 2 THEN
            /* <xml>
            <ToUserName><![CDATA[toUser]]></ToUserName>
            <FromUserName><![CDATA[fromUser]]></FromUserName>
            <CreateTime>12345678</CreateTime>
            <MsgType><![CDATA[image]]></MsgType>
            <Image>
            <MediaId><![CDATA[media_id]]></MediaId>
            </Image>
            </xml>*/
            SELECT b.media_id
            INTO v_medier_id
            FROM wx_attentionset a, wx_media b
            WHERE a.id = v_wx_attentionsetscan.id
            AND a.wx_media_id = b.id
            AND a.ad_client_id = b.ad_client_id
            AND a.ad_client_id = v_client_id;
            SELECT xmlelement("xml",
                               xmlelement("ToUserName",
                                           xmlcdata(v_fromusername) "XMLCData"),
                               xmlelement("FromUserName",
                                           xmlcdata(v_tousername) "XMLCData"),
                               xmlelement("CreateTime",
                                           to_char(SYSDATE, 'yyyymmddhhmiss')),
                               xmlelement("MsgType", xmlcdata('image') "XMLCData"),
                               xmlelement("Image",
                                           xmlelement("MediaId",
                                                       xmlcdata(v_medier_id)
                                                        "XMLCData")))
            INTO v_xml
            FROM dual;
            --raise_application_error(-20014, 'test');
        ELSIF v_wx_attentionsetscan.msgtype = 3 THEN
            /*<xml>
            <ToUserName><![CDATA[toUser]]></ToUserName>
            <FromUserName><![CDATA[fromUser]]></FromUserName>
            <CreateTime>12345678</CreateTime>
            <MsgType><![CDATA[voice]]></MsgType>
            <Voice>
            <MediaId><![CDATA[media_id]]></MediaId>
            </Voice>
            </xml>*/
            SELECT b.media_id
            INTO v_medier_id
            FROM wx_attentionset a, wx_media b
            WHERE a.id = v_wx_attentionsetscan.id
            AND a.wx_media_id = b.id
            AND a.ad_client_id = b.ad_client_id
            AND a.ad_client_id = v_client_id;
            SELECT xmlelement("xml",
                               xmlelement("ToUserName",
                                           xmlcdata(v_fromusername) "XMLCData"),
                               xmlelement("FromUserName",
                                           xmlcdata(v_tousername) "XMLCData"),
                               xmlelement("CreateTime",
                                           to_char(SYSDATE, 'yyyymmddhhmiss')),
                               xmlelement("MsgType", xmlcdata('voice') "XMLCData"),
                               xmlelement("Voice",
                                           xmlelement("MediaId",
                                                       xmlcdata(v_medier_id)
                                                        "XMLCData")))
            INTO v_xml
            FROM dual;
            --raise_application_error(-20014, 'test');
        ELSIF v_wx_attentionsetscan.msgtype = 4 THEN
            /*<xml>
            <ToUserName><![CDATA[toUser]]></ToUserName>
            <FromUserName><![CDATA[fromUser]]></FromUserName>
            <CreateTime>12345678</CreateTime>
            <MsgType><![CDATA[video]]></MsgType>
            <Video>
            <MediaId><![CDATA[media_id]]></MediaId>
            <Title><![CDATA[title]]></Title>
            <Description><![CDATA[description]]></Description>
            </Video>
            </xml>*/
            SELECT b.media_id
            INTO v_medier_id
            FROM wx_attentionset a, wx_media b
            WHERE a.id = v_wx_attentionsetscan.id
            AND a.wx_media_id = b.id
            AND a.ad_client_id = b.ad_client_id
            AND a.ad_client_id = v_client_id;
            SELECT xmlelement("xml",
                               xmlelement("ToUserName",
                                           xmlcdata(v_fromusername) "XMLCData"),
                               xmlelement("FromUserName",
                                           xmlcdata(v_tousername) "XMLCData"),
                               xmlelement("CreateTime",
                                           to_char(SYSDATE, 'yyyymmddhhmiss')),
                               xmlelement("MsgType", xmlcdata('video') "XMLCData"),
                               xmlelement("Video",
                                           xmlelement("MediaId",
                                                       xmlcdata(v_medier_id)
                                                        "XMLCData"),
                               xmlelement("Title",
                                           xmlcdata(v_wx_attentionsetscan.title)
                                            "XMLCData"),
                               xmlelement("Description",
                                           xmlcdata(v_wx_attentionsetscan.content)
                                            "XMLCData")))
            INTO v_xml
            FROM dual;
            --raise_application_error(-20014, 'test');
        ELSIF v_wx_attentionsetscan.msgtype = 5 THEN
            /*<xml>
            <ToUserName><![CDATA[toUser]]></ToUserName>
            <FromUserName><![CDATA[fromUser]]></FromUserName>
            <CreateTime>12345678</CreateTime>
            <MsgType><![CDATA[music]]></MsgType>
            <Music>
            <Title><![CDATA[TITLE]]></Title>
            <Description><![CDATA[DESCRIPTION]]></Description>
            <MusicUrl><![CDATA[MUSIC_Url]]></MusicUrl>
            <HQMusicUrl><![CDATA[HQ_MUSIC_Url]]></HQMusicUrl>
            <ThumbMediaId><![CDATA[media_id]]></ThumbMediaId>
            </Music>
            </xml>*/
            SELECT b.media_id
            INTO v_medier_id
            FROM wx_attentionset a, wx_media b
            WHERE a.id = v_wx_attentionsetscan.id
            AND a.wx_media_id = b.id
            AND a.ad_client_id = b.ad_client_id
            AND a.ad_client_id = v_client_id;
            SELECT xmlelement("xml",
                               xmlelement("ToUserName",
                                           xmlcdata(v_fromusername) "XMLCData"),
                               xmlelement("FromUserName",
                                           xmlcdata(v_tousername) "XMLCData"),
                               xmlelement("CreateTime",
                                           to_char(SYSDATE, 'yyyymmddhhmiss')),
                               xmlelement("MsgType", xmlcdata('music') "XMLCData"),
                               xmlelement("Music",
                                           xmlelement("Title",
                                                       xmlcdata(v_wx_attentionsetscan.title)
                                                        "XMLCData"),
                                           xmlelement("Description",
                                                       xmlcdata(v_wx_attentionsetscan.content)
                                                        "XMLCData"),
                                           xmlelement("MusicUrl",
                                                       xmlcdata(v_wx_attentionsetscan.url)
                                                        "XMLCData"),
                                           xmlelement("HQMusicUrl",
                                                       xmlcdata(v_wx_attentionsetscan.hurl)
                                                        "XMLCData"),
                                           xmlelement("ThumbMediaId",
                                                       xmlcdata(v_medier_id)
                                                        "XMLCData")))
            INTO v_xml
            FROM dual;
            --raise_application_error(-20014, 'test');
        ELSIF v_wx_attentionsetscan.msgtype = 6 THEN
            /*<xml>
            <ToUserName><![CDATA[toUser]]></ToUserName>
            <FromUserName><![CDATA[fromUser]]></FromUserName>
            <CreateTime>12345678</CreateTime>
            <MsgType><![CDATA[news]]></MsgType>
            <ArticleCount>2</ArticleCount>
            <Articles>
            <item>
            <Title><![CDATA[title1]]></Title>
            <Description><![CDATA[description1]]></Description>
            <PicUrl><![CDATA[picurl]]></PicUrl>
            <Url><![CDATA[url]]></Url>
            </item>
            <item>
            <Title><![CDATA[title]]></Title>
            <Description><![CDATA[description]]></Description>
            <PicUrl><![CDATA[picurl]]></PicUrl>
            <Url><![CDATA[url]]></Url>
            </item>
            </Articles>
            </xml> */
            SELECT xmlelement("xml",
                               xmlelement("ToUserName",
                                           xmlcdata(v_fromusername) "XMLCData"),
                               xmlelement("FromUserName",
                                           xmlcdata(v_tousername) "XMLCData"),
                               xmlelement("CreateTime",
                                           to_char(SYSDATE, 'yyyymmddhhmiss')),
                               xmlelement("MsgType", xmlcdata('news') "XMLCData"),
                               xmlelement("ArticleCount",
                                           v_wx_attentionsetscan.count),
                               xmlelement("Articles"))
            INTO v_xml
            FROM dual;
            SELECT appendchildxml(v_xml, 'xml/Articles',
                                   xmlagg(xmlelement("item",
                                                      (xmlforest(xmlcdata(nvl(s.title,
                                                                               ' ')) AS
                                                                  "Title",
                                                                  xmlcdata(nvl(s.content,
                                                                                ' ')) AS
                                                                   "Description",
                                                                  xmlcdata(nvl(v_domain||s.url,
                                                                                ' ')) AS
                                                                   "PicUrl",
                                                                  xmlcdata(CASE
                                                                                WHEN vj.url IS NULL OR vj.url = '' THEN
                                                                                 CASE WHEN vj.ID IS NULL THEN '#'
                                                                                 ELSE nvl(s.objid, ' ')
                                                                                 END
                                                                                ELSE
                                                                                v_sr1||case when v_publictype='4'
                                                                                                          then replace(apex_util.url_encode(replace(v_domain||nvl(vj.purl,''), '@ID@', nvl(s.objid, ' '))),'%2E','.')
                                                                                                          else replace(nvl(v_domain||vj.purl,''), '@ID@', nvl(s.objid, ' '))
                                                                                                     end
                                                                                         ||v_sr2
                                                                            END) AS
                                                                   "Url"))) ORDER BY
                                           s.sort asc))
            INTO v_xml
            FROM wx_attentionsetitem s LEFT JOIN wx_v_jumpurlpath vj ON vj.id = s.fromid+v_client_id
            WHERE s.wx_attentionset_id = v_wx_attentionsetscan.id and s.ad_client_id=v_client_id and vj.ad_client_id=v_client_id order by s.sort asc;
            --raise_application_error(-20014, 'test');
        END IF;
    END IF;
    RETURN v_xml.getclobval();
EXCEPTION
    WHEN OTHERS THEN
        RETURN '<xml>null</xml>';
END;

/
create or replace function wx_notify_$r_reply(p_ad_client_id in number,

                                              p_notifymember_id   in number,
																							p_notifymember_type in number)
    return clob is
    --------------------------------------------------------------
    --ADD BY PACO 2014061625
    --扫描自动回复信息
    --------------------------------------------------------------
    v_medier_id    varchar2(100);
    v_client_id    number(10);
    resultclob   clob;
    sqls         varchar2(2000);
    resultjo     json:=new json();
		tempjo       json:=new json();
		tempja       json_list:=new json_list();
    jos          json;
    joslist      json_list := new json_list;
    contentstr   varchar2(4000);
    v_fid        number(10);
    v_odreplace  varchar2(4000);
    v_replace    varchar2(4000);
    v_receive    varchar2(4000);
    v_url        varchar2(4000);
    v_url1       varchar2(4000);
    v_content    varchar2(4000);
    v_sr1        varchar2(4000);
    v_sr2        varchar2(4000);
    v_appid      varchar2(100);
    v_publictype char(1);
    v_domain     varchar2(4000);
    v_wx_notify wx_notify%rowtype;
begin
    v_client_id := p_ad_client_id;
    select s.*
    into   v_wx_notify
    from   wx_notify s join wx_notifymember v on s.id=v.wx_notify_id
    where  v.id=p_notifymember_id
		and  v.type=p_notifymember_type
		and v.state='N';
    select s.appid, s.publictype
    into   v_appid, v_publictype
    from   wx_interfaceset s
    where  s.ad_client_id = v_client_id;
    select 'http://' || wc.domain
    into   v_domain
    from   web_client wc
    where  wc.ad_client_id = v_client_id;
    if v_publictype = '4' then
        v_sr1 := 'https://open.weixin.qq.com/connect/oauth2/authorize?appid=' ||
                 v_appid || '&redirect_uri=';
        v_sr2 := '&response_type=code&scope=snsapi_base&state=1#wechat_redirect';
    else
        v_sr1 := '';
        v_sr2 := '';
    end if;
    resultjo.put('touser','');
    if v_wx_notify.msgtype = 1 then
        /* <xml>
        <ToUserName><![CDATA[toUser]]></ToUserName>
        <FromUserName><![CDATA[fromUser]]></FromUserName>
        <CreateTime>12345678</CreateTime>
        <MsgType><![CDATA[text]]></MsgType>
        <Content><![CDATA[你好]]></Content>
        </xml>*/
        --jos := json(v_wx_notify.urlcontent);
        v_content := v_wx_notify.content;
        if v_wx_notify.urlcontent is not null then
            begin
                joslist := json_list(v_wx_notify.urlcontent);
            exception
                when others then
                    joslist := json_list();
            end;
            -- joslist := json_ext.get_json_list(jos, 'list');
            for v in 1 .. joslist.count loop
                jos        := json(joslist.get_elem(v));
                v_fid       := jos.get('fromid').get_number;
                v_odreplace := jos.get('oldreplace').get_string;
                v_replace   := jos.get('replace').get_string;
                v_receive   := jos.get('receive').get_string;
                begin
                    select t.purl
                    into   v_url
                    from   wx_v_jumpurlpath t
                    where  t.id = v_fid+v_client_id and t.ad_client_id=v_client_id;
                exception
                    when no_data_found then
                        v_url     := null;
                        v_replace := '#';
                end;
                if v_url is null then
                    v_url1 := v_replace;
                else
                    v_url1 := v_sr1 ||case when v_publictype='4' then replace(apex_util.url_encode(REPLACE( v_domain ||v_url, v_odreplace, v_replace)),'%2E','.') else REPLACE( v_domain ||v_url, v_odreplace, v_replace) end ||v_sr2;
                end if;
                contentstr := v_content;
                v_content  := replace(contentstr, v_receive, v_url1);
            end loop;
        end if;
				resultjo.put('msgtype','text');
				tempjo.put('content',v_content);
				resultjo.put('text',tempjo);
        -- raise_application_error(-20014, 'test');
    elsif v_wx_notify.msgtype = 2 then
        /* <xml>
        <ToUserName><![CDATA[toUser]]></ToUserName>
        <FromUserName><![CDATA[fromUser]]></FromUserName>
        <CreateTime>12345678</CreateTime>
        <MsgType><![CDATA[image]]></MsgType>
        <Image>
        <MediaId><![CDATA[media_id]]></MediaId>
        </Image>
        </xml>*/
        select b.media_id
        into   v_medier_id
        from   wx_notify a, wx_media b
        where  a.id = v_wx_notify.id
        and    a.wx_media_id = b.id
        and    a.ad_client_id = b.ad_client_id
        and    a.ad_client_id = v_client_id;
				resultjo.put('msgtype','image');
				tempjo.put('media_id',v_medier_id);
				resultjo.put('image',tempjo);
        --raise_application_error(-20014, 'test');
    elsif v_wx_notify.msgtype = 3 then
        /*<xml>
        <ToUserName><![CDATA[toUser]]></ToUserName>
        <FromUserName><![CDATA[fromUser]]></FromUserName>
        <CreateTime>12345678</CreateTime>
        <MsgType><![CDATA[voice]]></MsgType>
        <Voice>
        <MediaId><![CDATA[media_id]]></MediaId>
        </Voice>
        </xml>*/
        select b.media_id
        into   v_medier_id
        from   wx_notify a, wx_media b
        where  a.id = v_wx_notify.id
        and    a.wx_media_id = b.id
        and    a.ad_client_id = b.ad_client_id
        and    a.ad_client_id = v_client_id;
		    resultjo.put('msgtype','voice');
				tempjo.put('media_id',v_medier_id);
				resultjo.put('voice',tempjo);
        --raise_application_error(-20014, 'test');
    elsif v_wx_notify.msgtype = 4 then
        /*<xml>
        <ToUserName><![CDATA[toUser]]></ToUserName>
        <FromUserName><![CDATA[fromUser]]></FromUserName>
        <CreateTime>12345678</CreateTime>
        <MsgType><![CDATA[video]]></MsgType>
        <Video>
        <MediaId><![CDATA[media_id]]></MediaId>
        <Title><![CDATA[title]]></Title>
        <Description><![CDATA[description]]></Description>
        </Video>
        </xml>*/
        select b.media_id
        into   v_medier_id
        from   wx_notify a, wx_media b
        where  a.id = v_wx_notify.id
        and    a.wx_media_id = b.id
        and    a.ad_client_id = b.ad_client_id
        and    a.ad_client_id = v_client_id;
		    resultjo.put('msgtype','video');
				tempjo.put('media_id',v_medier_id);
				tempjo.put('title',v_wx_notify.title);
				tempjo.put('description',v_wx_notify.content);
				resultjo.put('video',tempjo);
        --raise_application_error(-20014, 'test');
    elsif v_wx_notify.msgtype = 5 then
        /*<xml>
        <ToUserName><![CDATA[toUser]]></ToUserName>
        <FromUserName><![CDATA[fromUser]]></FromUserName>
        <CreateTime>12345678</CreateTime>
        <MsgType><![CDATA[music]]></MsgType>
        <Music>
        <Title><![CDATA[TITLE]]></Title>
        <Description><![CDATA[DESCRIPTION]]></Description>
        <MusicUrl><![CDATA[MUSIC_Url]]></MusicUrl>
        <HQMusicUrl><![CDATA[HQ_MUSIC_Url]]></HQMusicUrl>
        <ThumbMediaId><![CDATA[media_id]]></ThumbMediaId>
        </Music>
        </xml>*/
        select b.media_id
        into   v_medier_id
        from   wx_notify a, wx_media b
        where  a.id = v_wx_notify.id
        and    a.wx_media_id = b.id
        and    a.ad_client_id = b.ad_client_id
        and    a.ad_client_id = v_client_id;
		    resultjo.put('msgtype','music');
				tempjo.put('title',v_wx_notify.title);
				tempjo.put('description',v_wx_notify.content);
				tempjo.put('musicurl',v_wx_notify.url);
				tempjo.put('hqmusicurl',v_wx_notify.hurl);
				tempjo.put('thumb_media_id',v_medier_id);
				resultjo.put('music',tempjo);
        --raise_application_error(-20014, 'test');
    elsif v_wx_notify.msgtype = 6 then
        /*<xml>
        <ToUserName><![CDATA[toUser]]></ToUserName>
        <FromUserName><![CDATA[fromUser]]></FromUserName>
        <CreateTime>12345678</CreateTime>
        <MsgType><![CDATA[news]]></MsgType>
        <ArticleCount>2</ArticleCount>
        <Articles>
        <item>
        <Title><![CDATA[title1]]></Title>
        <Description><![CDATA[description1]]></Description>
        <PicUrl><![CDATA[picurl]]></PicUrl>
        <Url><![CDATA[url]]></Url>
        </item>
        <item>
        <Title><![CDATA[title]]></Title>
        <Description><![CDATA[description]]></Description>
        <PicUrl><![CDATA[picurl]]></PicUrl>
        <Url><![CDATA[url]]></Url>
        </item>
        </Articles>
        </xml> */
				resultjo.put('msgtype','news');
        sqls:='select nvl(s.title, '''') as "title",to_char(nvl(s.content, '''')) as "description",nvl('''||v_domain||''' ||s.url, '''') as "picurl",
				      (case
										when vj.url is null or vj.url = '''' then
										 case
												 when vj.id is null then
													''#''
												 else
													nvl(s.objid, '''')
										 end
										else
										 '''||v_sr1||''' || case
												 when '''||v_publictype||''' = ''4'' then
													replace(apex_util.url_encode(replace(nvl('''||v_domain||'''||vj.purl, ''''),
																															 ''@ID@'',
																													 nvl(s.objid, ''''))),
																	''%2E'',
																	''.'')
												 else
													replace(nvl('''||v_domain||'''||vj.purl, ''''), ''@ID@'', nvl(s.objid, ''''))
										 end || '''||v_sr2||'''
								end) as "url"
				from   wx_noitfyitem s
        left   join wx_v_jumpurlpath vj
        on     vj.id = s.fromid+'||v_client_id||'
        where  vj.ad_client_id='||v_client_id||' and s.ad_client_id='||v_client_id||' and s.groupid = '||v_wx_notify.groupid||'
        order  by s.sort asc';
				dbms_output.put_line(sqls);
        tempja := json_dyn.executeList(sqls);
				tempjo.put('articles',tempja);
		    resultjo.put('news',tempjo);
        --raise_application_error(-20014, 'test');
    end if;
    resultclob:=empty_clob();
    resultjo.to_clob(resultclob,true);
		return resultclob;
		--return resultjo.to_char(false);
exception when others then
    resultclob:=empty_clob();
    dbms_lob.createtemporary(resultclob, true);
    resultjo.to_clob(resultclob);
    return resultclob;
		--return resultjo.to_char(false);
end;

/
create or replace FUNCTION wx_rqcodemessage_$r_scan(p_user_id IN NUMBER,

                                                p_query   IN VARCHAR2)
    RETURN CLOB IS
    --------------------------------------------------------------
    --ADD BY PACO 20140924
    --扫描二维码处理
    --------------------------------------------------------------
    st_xml VARCHAR2(32676);
    v_xml  xmltype;
    TYPE t_queryobj IS RECORD(
        fromusername VARCHAR2(200),
        tousername   VARCHAR2(200),
        msgtype      VARCHAR2(80),
        eventkey     VARCHAR2(200),
				ticket       varchar2(200));
    v_queryobj t_queryobj;
    v_eventkey     VARCHAR2(1500);
    v_fromusername VARCHAR2(200);
    v_tousername   VARCHAR2(200);
    v_mstype       VARCHAR2(80);
    v_medier_id    VARCHAR2(100);
    v_count       NUMBER(10);
    v_client_id    NUMBER(10);
    jos1         json;
    joslist      json_list := NEW json_list;
    contentstr   VARCHAR2(4000);
    v_fid        NUMBER(10);
    v_odreplace  VARCHAR2(4000);
    v_replace    VARCHAR2(4000);
    v_receive    VARCHAR2(4000);
    v_url        VARCHAR2(4000);
    v_url1       VARCHAR2(4000);
    v_content    VARCHAR2(4000);
    v_sr1        VARCHAR2(4000);
    v_sr2        VARCHAR2(4000);
    v_appid      VARCHAR2(100);
    v_publictype CHAR(1);
		v_ticket     varchar2(200);
    v_domain     VARCHAR2(4000);
		v_actiontype varchar2(100);
    v_wx_rqcodemessage wx_rqcodemessage%ROWTYPE;
BEGIN
    -- 从p_query解析数据
    st_xml := p_query;
    v_xml := xmltype(st_xml);
    SELECT extractvalue(VALUE(t), '/xml/FromUserName'),
           extractvalue(VALUE(t), '/xml/ToUserName'),
           extractvalue(VALUE(t), '/xml/MsgType'),
           extractvalue(VALUE(t), '/xml/EventKey'),
					 extractvalue(VALUE(t), '/xml/Ticket')
    INTO v_queryobj
    FROM TABLE(xmlsequence(extract(v_xml, '/xml'))) t;
		v_ticket:=v_queryobj.ticket;
    v_eventkey := v_queryobj.eventkey;
    v_fromusername := v_queryobj.fromusername;
    v_tousername := v_queryobj.tousername;
    --raise_application_error(-20014, 'ad_client_id:' || p_user_id || p_query);
    v_client_id := p_user_id;
    SELECT COUNT(*)
    INTO v_count
    FROM wx_rqcodemessage t
    WHERE t.rqcodeparam = v_eventkey
    AND t.isenable = 'Y'
    AND t.ad_client_id = v_client_id;
    IF v_count <> 0 THEN
        SELECT *
        INTO v_wx_rqcodemessage
        FROM wx_rqcodemessage t
        WHERE t.rqcodeparam = v_eventkey
        AND t.isenable = 'Y'
        AND t.ad_client_id = v_client_id;
        SELECT s.appid, s.publictype
        INTO v_appid, v_publictype
        FROM wx_interfaceset s
        WHERE s.ad_client_id = v_client_id;
        SELECT 'http://'||wc.domain
        INTO v_domain
        FROM web_client wc
        WHERE wc.ad_client_id = v_client_id;
        IF v_publictype = '4' THEN
           v_sr1 := 'https://open.weixin.qq.com/connect/oauth2/authorize?appid=' ||
                     v_appid || '&redirect_uri=';
           v_sr2 := '&response_type=code&scope=snsapi_base&state=1#wechat_redirect';
        ELSE
           v_sr1:='';
           v_sr2:='';
        END IF;
        IF v_wx_rqcodemessage.msgtype = 'Words' THEN
            /* <xml>
            <ToUserName><![CDATA[toUser]]></ToUserName>
            <FromUserName><![CDATA[fromUser]]></FromUserName>
            <CreateTime>12345678</CreateTime>
            <MsgType><![CDATA[text]]></MsgType>
            <Content><![CDATA[你好]]></Content>
            </xml> */
            --jos := json(v_wx_messageauto.urlcontent);
            v_content := v_wx_rqcodemessage.content;
            --joslist := json_ext.get_json_list(jos, 'list');
            IF v_wx_rqcodemessage.urlcontent IS NOT NULL THEN
                BEGIN
                   joslist := json_list(v_wx_rqcodemessage.urlcontent);
                EXCEPTION WHEN OTHERS THEN
                   joslist :=json_list();
               END;
                FOR v IN 1 .. joslist.count LOOP
                    jos1 := json(joslist.get_elem(v));
                    v_fid := jos1.get('fromid').get_number;
                    v_odreplace := jos1.get('oldreplace').get_string;
                    v_replace := jos1.get('replace').get_string;
                    v_receive := jos1.get('receive').get_string;
                    BEGIN
                      SELECT t.purl
                      INTO v_url
                      FROM wx_v_jumpurlpath t
                      WHERE t.id = v_fid+v_client_id and t.ad_client_id=v_client_id;
                    EXCEPTION WHEN no_data_found THEN
                      v_url:=NULL;
                      v_replace:='#';
                    END;
                    IF v_url IS NULL THEN
                        v_url1 := v_replace;
                    ELSE
                        v_url1 := v_sr1 ||v_domain || REPLACE(v_url, v_odreplace, v_replace)|| v_sr2;
                    END IF;
                    contentstr := v_content;
                    v_content := REPLACE(contentstr, v_receive, v_url1);
                END LOOP;
            END IF;
            v_mstype := 'text';
            SELECT xmlelement("xml",
                               xmlelement("ToUserName",
                                           xmlcdata(v_fromusername) "XMLCData"),
                               xmlelement("FromUserName",
                                           xmlcdata(v_tousername) "XMLCData"),
                               xmlelement("CreateTime",
                                           to_char(SYSDATE, 'yyyymmddhhmiss')),
                               xmlelement("MsgType", xmlcdata(v_mstype) "XMLCData"),
                               xmlelement("Content",
                                           xmlcdata(v_content /*v_wx_messageauto.content*/)
                                            "XMLCData"))
            INTO v_xml
            FROM dual;
            -- raise_application_error(-20014, 'test');
        ELSIF v_wx_rqcodemessage.msgtype = 'Image' THEN
            /* <xml>
            <ToUserName><![CDATA[toUser]]></ToUserName>
            <FromUserName><![CDATA[fromUser]]></FromUserName>
            <CreateTime>12345678</CreateTime>
            <MsgType><![CDATA[image]]></MsgType>
            <Image>
            <MediaId><![CDATA[media_id]]></MediaId>
            </Image>
            </xml>*/
            v_mstype := 'image';
            SELECT b.media_id
            INTO v_medier_id
            FROM wx_messageautoq a, wx_media b
            WHERE a.id = v_wx_rqcodemessage.id
            AND a.wx_media_id = b.id
            AND a.ad_client_id = b.ad_client_id
            AND a.ad_client_id = v_client_id;
            SELECT xmlelement("xml",
                               xmlelement("ToUserName",
                                           xmlcdata(v_fromusername) "XMLCData"),
                               xmlelement("FromUserName",
                                           xmlcdata(v_tousername) "XMLCData"),
                               xmlelement("CreateTime", SYSDATE),
                               xmlelement("MsgType", xmlcdata(v_mstype) "XMLCData"),
                               xmlelement("Image",
                                           xmlelement("MediaId",
                                                       xmlcdata(v_medier_id)
                                                        "XMLCData")))
            INTO v_xml
            FROM dual;
            --raise_application_error(-20014, 'test');
        ELSIF v_wx_rqcodemessage.msgtype = 'Voice' THEN
            /*<xml>
            <ToUserName><![CDATA[toUser]]></ToUserName>
            <FromUserName><![CDATA[fromUser]]></FromUserName>
            <CreateTime>12345678</CreateTime>
            <MsgType><![CDATA[voice]]></MsgType>
            <Voice>
            <MediaId><![CDATA[media_id]]></MediaId>
            </Voice>
            </xml>*/
            v_mstype := 'voice';
            SELECT b.media_id
            INTO v_medier_id
            FROM wx_messageautoq a, wx_media b
            WHERE a.id = v_wx_rqcodemessage.id
            AND a.wx_media_id = b.id
            AND a.ad_client_id = b.ad_client_id
            AND a.ad_client_id = v_client_id;
            SELECT xmlelement("xml",
                               xmlelement("ToUserName",
                                           xmlcdata(v_fromusername) "XMLCData"),
                               xmlelement("FromUserName",
                                           xmlcdata(v_tousername) "XMLCData"),
                               xmlelement("CreateTime",
                                           to_char(SYSDATE, 'yyyymmddhhmiss')),
                               xmlelement("MsgType", xmlcdata(v_mstype) "XMLCData"),
                               xmlelement("Voice",
                                           xmlelement("MediaId",
                                                       xmlcdata(v_medier_id)
                                                        "XMLCData")))
            INTO v_xml
            FROM dual;
            --raise_application_error(-20014, 'test');
        ELSIF v_wx_rqcodemessage.msgtype = 'Video' THEN
            /*<xml>
            <ToUserName><![CDATA[toUser]]></ToUserName>
            <FromUserName><![CDATA[fromUser]]></FromUserName>
            <CreateTime>12345678</CreateTime>
            <MsgType><![CDATA[video]]></MsgType>
            <Video>
            <MediaId><![CDATA[media_id]]></MediaId>
            <Title><![CDATA[title]]></Title>
            <Description><![CDATA[description]]></Description>
            </Video>
            </xml>*/
            v_mstype := 'video';
            SELECT b.media_id
            INTO v_medier_id
            FROM wx_messageautoq a, wx_media b
            WHERE a.id = v_wx_rqcodemessage.id
            AND a.wx_media_id = b.id
            AND a.ad_client_id = b.ad_client_id
            AND a.ad_client_id = v_client_id;
            SELECT xmlelement("xml",
                               xmlelement("ToUserName",
                                           xmlcdata(v_fromusername) "XMLCData"),
                               xmlelement("FromUserName",
                                           xmlcdata(v_tousername) "XMLCData"),
                               xmlelement("CreateTime",
                                           to_char(SYSDATE, 'yyyymmddhhmiss')),
                               xmlelement("MsgType", xmlcdata(v_mstype) "XMLCData"),
                               xmlelement("Video",
                                           xmlelement("MediaId",
                                                       xmlcdata(v_medier_id)
                                                        "XMLCData"),
                               xmlelement("Title",
                                           xmlcdata(v_wx_rqcodemessage.title)
                                            "XMLCData"),
                               xmlelement("Description",
                                           xmlcdata(v_wx_rqcodemessage.content)
                                            "XMLCData")))
            INTO v_xml
            FROM dual;
            --raise_application_error(-20014, 'test');
        ELSIF v_wx_rqcodemessage.msgtype = 'Music' THEN
            /*<xml>
            <ToUserName><![CDATA[toUser]]></ToUserName>
            <FromUserName><![CDATA[fromUser]]></FromUserName>
            <CreateTime>12345678</CreateTime>
            <MsgType><![CDATA[music]]></MsgType>
            <Music>
            <Title><![CDATA[TITLE]]></Title>
            <Description><![CDATA[DESCRIPTION]]></Description>
            <MusicUrl><![CDATA[MUSIC_Url]]></MusicUrl>
            <HQMusicUrl><![CDATA[HQ_MUSIC_Url]]></HQMusicUrl>
            <ThumbMediaId><![CDATA[media_id]]></ThumbMediaId>
            </Music>
            </xml>*/
            v_mstype := 'music';
            SELECT b.media_id
            INTO v_medier_id
            FROM wx_messageautoq a, wx_media b
            WHERE a.id = v_wx_rqcodemessage.id
            AND a.wx_media_id = b.id
            AND a.ad_client_id = b.ad_client_id
            AND a.ad_client_id = v_client_id;
            SELECT xmlelement("xml",
                               xmlelement("ToUserName",
                                           xmlcdata(nvl(v_fromusername, ' '))
                                            "XMLCData"),
                               xmlelement("FromUserName",
                                           xmlcdata(v_tousername) "XMLCData"),
                               xmlelement("CreateTime",
                                           to_char(SYSDATE, 'yyyymmddhhmiss')),
                               xmlelement("MsgType", xmlcdata(v_mstype) "XMLCData"),
                               xmlelement("Music",
                                           xmlelement("Title",
                                                       xmlcdata(v_wx_rqcodemessage.title)
                                                        "XMLCData"),
                                           xmlelement("Description",
                                                       xmlcdata(v_wx_rqcodemessage.content)
                                                        "XMLCData"),
                                           xmlelement("MusicUrl",
                                                       xmlcdata(v_wx_rqcodemessage.url)
                                                        "XMLCData"),
                                           xmlelement("HQMusicUrl",
                                                       xmlcdata(v_wx_rqcodemessage.hurl)
                                                        "XMLCData"),
                                           xmlelement("ThumbMediaId",
                                                       xmlcdata(v_medier_id)
                                                        "XMLCData")))
            INTO v_xml
            FROM dual;
            --raise_application_error(-20014, 'test');
        ELSIF v_wx_rqcodemessage.msgtype = 'News' THEN
            /*<xml>
            <ToUserName><![CDATA[toUser]]></ToUserName>
            <FromUserName><![CDATA[fromUser]]></FromUserName>
            <CreateTime>12345678</CreateTime>
            <MsgType><![CDATA[news]]></MsgType>
            <ArticleCount>2</ArticleCount>
            <Articles>
            <item>
            <Title><![CDATA[title1]]></Title>
            <Description><![CDATA[description1]]></Description>
            <PicUrl><![CDATA[picurl]]></PicUrl>
            <Url><![CDATA[url]]></Url>
            </item>
            <item>
            <Title><![CDATA[title]]></Title>
            <Description><![CDATA[description]]></Description>
            <PicUrl><![CDATA[picurl]]></PicUrl>
            <Url><![CDATA[url]]></Url>
            </item>
            </Articles>
            </xml> */
            --raise_application_error(-20014, v_wx_messageauto.count);
            v_mstype := 'news';
            SELECT xmlelement("xml",
                               xmlelement("ToUserName",
                                           xmlcdata(nvl(v_fromusername, ' '))
                                            "XMLCData"),
                               xmlelement("FromUserName",
                                           xmlcdata(nvl(v_tousername, ' '))
                                            "XMLCData"),
                               xmlelement("CreateTime",
                                           to_char(SYSDATE, 'yyyymmddhhmiss')),
                               xmlelement("MsgType", xmlcdata(v_mstype) "XMLCData"),
                               xmlelement("ArticleCount", v_wx_rqcodemessage.count),
                               xmlelement("Articles"))
            INTO v_xml
            FROM dual;
            SELECT appendchildxml(v_xml, 'xml/Articles',
                                   xmlagg(xmlelement("item",
                                                      (xmlforest(xmlcdata(nvl(s.title,
                                                                               ' ')) AS
                                                                  "Title",
                                                                  xmlcdata(nvl(s.content,
                                                                                ' ')) AS
                                                                   "Description",
																																	 xmlcdata(case when instr(s.url,'@',1,1)>0 then replace(nvl(s.url,''),'@','') else nvl(v_domain||s.url,'') end)
                                                                   AS
                                                                   "PicUrl",
                                                                  xmlcdata(CASE
                                                                                WHEN nvl(vj.url,'') = '' THEN
                                                                                 CASE WHEN vj.id is NULL THEN '#'
                                                                                 ELSE nvl(s.objid, ' ')
                                                                                 END
                                                                                ELSE
                                                                                v_sr1||case when v_publictype='4'
                                                                                                          then replace(apex_util.url_encode(replace(v_domain||nvl(vj.purl,''), '@ID@', nvl(s.objid, ' '))),'%2E','.')
                                                                                                          else replace(nvl(v_domain||vj.purl,''), '@ID@', nvl(s.objid, ' '))
                                                                                                     end
                                                                                         ||v_sr2
                                                                            END) AS
                                                                   "Url"))) ORDER BY
                                           s.sort asc))
            INTO v_xml
            FROM wx_rqcodemessageitem s LEFT JOIN wx_v_jumpurlpath vj ON vj.id = s.fromid+v_client_id
            WHERE s.wx_rqcodemessage_id = v_wx_rqcodemessage.id and s.ad_client_id=v_client_id and vj.ad_client_id=v_client_id order by s.sort asc;
        ELSIF v_wx_rqcodemessage.msgtype = 'Action' THEN
				    v_mstype := 'action';
						v_actiontype:=v_wx_rqcodemessage.actiontype;
						v_content:=to_char(v_wx_rqcodemessage.content);
            SELECT xmlelement("xml",
                               xmlelement("ToUserName",xmlcdata(v_fromusername) "XMLCData"),
                               xmlelement("FromUserName",xmlcdata(v_tousername) "XMLCData"),
                               xmlelement("CreateTime",to_char(SYSDATE, 'yyyymmddhhmiss')),
                               xmlelement("MsgType", xmlcdata(v_mstype) "XMLCData"),
                               xmlelement("Content",xmlcdata(v_content) "XMLCData"),
															 xmlelement("ActionType",xmlcdata(v_actiontype) "XMLCData")
															 )
            INTO v_xml
            FROM dual;
				END IF;
        --raise_application_error(-20014, 'test');
    END IF;
    RETURN v_xml.getclobval();
EXCEPTION
    WHEN OTHERS THEN
        RETURN '<xml>null</xml>';
END;

/
create or replace PROCEDURE wx_order_sendpaysms(p_user_id IN NUMBER,

                                           p_query   IN VARCHAR2,
                                           r_code    OUT NUMBER,
                                           r_message OUT VARCHAR2) AS
BEGIN
    null;
end;

/
create or replace procedure wx_order_send(p_user_id in number,

                                             p_query in varchar2,
                                             r_Code OUT NUMBER,
                                             r_Message OUT VARCHAR2) AS
    ------------------------------------------------------------
    --add by cyl 确认发货
    ------------------------------------------------------------
    v_wx_order wx_order%rowtype;
    TYPE t_queryobj IS RECORD(
        "table" VARCHAR2(255),
        query   varchar2(32676),
        id      varchar2(10));
    v_queryobj t_queryobj;
      st_xml      varchar2(32676);
    v_xml       xmltype;
        type t_selection is table of number(10) index by binary_integer;
    v_selection t_selection;
      p_id        number(10);
begin
  st_xml := '<data>' || p_query || '</data>';
    v_xml  := xmltype(st_xml);
    select extractvalue(VALUE(t), '/data/table'),
           extractvalue(VALUE(t), '/data/query'),
           extractvalue(VALUE(t), '/data/id')
    into v_queryobj
    from TABLE(XMLSEQUENCE(EXTRACT(v_xml, '/data'))) t;
    select extractvalue(VALUE(t), '/selection') bulk collect
    into v_selection
    from TABLE(XMLSEQUENCE(EXTRACT(v_xml, '/data/selection'))) t;
   -- for v in 1..v_selection.count loop
    p_id:=v_queryobj.id;
    select * into v_wx_order from wx_order t where t.id = p_id;
     r_code:=1;
    if v_wx_order.LOGISTICS_CODE is not null and v_wx_order.sale_status=3 then
        update wx_order t
        set t.sale_status = 8, t.modifierid = p_user_id,
            t.modifieddate = sysdate
        where t.id = p_id;
        r_code    := 5;
        r_Message := 'var w = window.opener;
                      if(!w){w= window.parent;}
                      if(w){w.pc.objectReback("WX_V_SHIPPING_ORDER","null",this);}';
    elsif v_wx_order.LOGISTICS_CODE is null and v_wx_order.sale_status=3 then
       --- r_code    := 0;
        r_Message := '单据号：'||v_wx_order.docno||'缺少物流单号!<br>'||r_Message;
    elsif v_wx_order.sale_status!=3 then
           r_Message := '单据号：'||v_wx_order.docno||'不是待发货单据!<br>'||r_Message;
    end if;
   -- end loop;
end;

/
create or replace function wx_notify_crowdreply(f_adclientid in number)

    return clob is
    returnclob clob;
    tempsql    varchar2(5000);
    resultja   json_list := new json_list();
    tempjo     json;
    membersja  json_list;
    memberids  varchar2(1000):=null;
    member_reply clob;
begin
  	returnclob:=empty_clob();
		dbms_lob.createtemporary(returnclob,true);
    for f in (select nm.id,nm.wx_notify_id,
                     trim(nvl(nm.massopenid, '')) as condition,nm.ad_client_id
              from   wx_notifymember nm
              --where  nm.ad_client_id = f_adclientid
              where  nm.type=1
              and    nm.state = 'N'
              and    nvl(nm.errcount,0)<=5
							and rownum<=1
							--order by nm.creationdate desc,nm.modifieddate asc
              ) loop
              --dbms_output.put_line(f.wx_notify_id);
        if f.condition is null then
				    update wx_notifymember nm set nm.modifieddate=sysdate,nm.errcount=nvl(nm.errcount,0)+1,nm.errorlog='massopenid is null' where nm.id=f.id;
            continue;
        end if;
				begin
						tempsql      := 'select v.wechatno as "openid" from wx_vip v where v.ad_client_id=' ||
														f.ad_client_id || ' and v.id ' || f.condition;
		    exception when others then
				    update wx_notifymember nm set nm.modifieddate=sysdate,nm.errcount=nvl(nm.errcount,0)+1,nm.errorlog='condition is too large' where nm.id=f.id;
            continue;
				end;
        membersja    := json_dyn.executelist(tempsql);
        member_reply := wx_notify_$r_reply(f.ad_client_id, f.id,1);
        dbms_output.put_line(member_reply);
        if member_reply is null or membersja.count<=0 then
           update wx_notifymember nm set nm.modifieddate=sysdate,nm.errcount=nvl(nm.errcount,0)+1,nm.errorlog='reply is null or member is null' where nm.id=f.id;
           continue;
        end if;
        tempjo       := new json();
        begin
            tempjo.put('id', f.id);
            tempjo.put('reply', new json(member_reply));
            tempjo.put('members', membersja.to_json_value);
            tempjo.put('ad_client_id',f.ad_client_id);
            resultja.add_elem(tempjo.to_json_value);
            dbms_output.put_line(tempjo.to_char);
            --resultja.to_clob(returnclob,true);
        exception when others then
            update wx_notifymember nm set nm.modifieddate=sysdate,nm.errcount=nvl(nm.errcount,0)+1,nm.errorlog='init jo error' where nm.id=f.id;
            dbms_output.put_line(sqlerrm);
        end;
        if memberids is null then
           memberids:='';
        else
           memberids:=memberids||',';
        end if;
        memberids:=memberids||f.id;
    end loop;
    begin
        resultja.to_clob(returnclob,false);
    exception when others then
        update wx_notifymember nm set nm.modifieddate=sysdate,nm.errcount=nvl(nm.errcount,0)+1,nm.errorlog='to_clob error' where nm.id in(memberids);
        dbms_output.put_line(sqlerrm);
    end;
    return returnclob;
end;

/
create or replace function getsendsmscount(f_company_id in number)

    return number is
    f_sendsmscount number(10);
begin
    select count(1)
    into   f_sendsmscount
    from   u_message e
		where    e.ad_client_id=f_company_id
    and    e.state = 2;
    return f_sendsmscount;
end;

/
create or replace function wx_notify_crowdreply(f_adclientid in number)

    return clob is
    returnclob clob;
    tempsql    varchar2(5000);
    resultja   json_list := new json_list();
    tempjo     json;
    membersja  json_list;
    memberids  varchar2(1000):=null;
    member_reply clob;
begin
  	returnclob:=empty_clob();
		dbms_lob.createtemporary(returnclob,true);
    for f in (select nm.id,nm.wx_notify_id,
                     trim(nvl(nm.massopenid, '')) as condition,nm.ad_client_id
              from   wx_notifymember nm
              --where  nm.ad_client_id = f_adclientid
              where  nm.type=1
              and    nm.state = 'N'
              and    nvl(nm.errcount,0)<=5
							and rownum<=1
							--order by nm.creationdate desc,nm.modifieddate asc
              ) loop
              --dbms_output.put_line(f.wx_notify_id);
        if f.condition is null then
				    update wx_notifymember nm set nm.modifieddate=sysdate,nm.errcount=nvl(nm.errcount,0)+1,nm.errorlog='massopenid is null' where nm.id=f.id;
            continue;
        end if;
				begin
						tempsql      := 'select v.wechatno as "openid" from wx_vip v where v.ad_client_id=' ||
														f.ad_client_id || ' and v.id ' || f.condition;
		    exception when others then
				    update wx_notifymember nm set nm.modifieddate=sysdate,nm.errcount=nvl(nm.errcount,0)+1,nm.errorlog='condition is too large' where nm.id=f.id;
            continue;
				end;
        membersja    := json_dyn.executelist(tempsql);
        member_reply := wx_notify_$r_reply(f.ad_client_id, f.id,1);
        dbms_output.put_line(member_reply);
        if member_reply is null or membersja.count<=0 then
           update wx_notifymember nm set nm.modifieddate=sysdate,nm.errcount=nvl(nm.errcount,0)+1,nm.errorlog='reply is null or member is null' where nm.id=f.id;
           continue;
        end if;
        tempjo       := new json();
        begin
            tempjo.put('id', f.id);
            tempjo.put('reply', new json(member_reply));
            tempjo.put('members', membersja.to_json_value);
            tempjo.put('ad_client_id',f.ad_client_id);
            resultja.add_elem(tempjo.to_json_value);
            dbms_output.put_line(tempjo.to_char);
            --resultja.to_clob(returnclob,true);
        exception when others then
            update wx_notifymember nm set nm.modifieddate=sysdate,nm.errcount=nvl(nm.errcount,0)+1,nm.errorlog='init jo error' where nm.id=f.id;
            dbms_output.put_line(sqlerrm);
        end;
        if memberids is null then
           memberids:='';
        else
           memberids:=memberids||',';
        end if;
        memberids:=memberids||f.id;
    end loop;
    begin
        resultja.to_clob(returnclob,false);
    exception when others then
        update wx_notifymember nm set nm.modifieddate=sysdate,nm.errcount=nvl(nm.errcount,0)+1,nm.errorlog='to_clob error' where nm.id in(memberids);
        dbms_output.put_line(sqlerrm);
    end;
    return returnclob;
end;

/
create or replace FUNCTION WX_SPEC_$R_DELETEITEM(P_USERS_ID IN NUMBER,

                                                 P_STR      IN VARCHAR2)
  RETURN VARCHAR2 IS
  V_WX_VIPBASESET_ID NUMBER(10);
  V_AD_CLIENT_ID     NUMBER(10);
  JO                 JSON := NEW JSON();
  SCOUNT             NUMBER(10);
  SECTION            VARCHAR2(100);
  P_ID               NUMBER(10);
  C_ID               NUMBER(10);
  PJO                JSON;
BEGIN
  PJO  := NEW JSON(P_STR);
  P_ID := PJO.GET('p_id').GET_NUMBER;
  C_ID := PJO.GET('c_id').GET_NUMBER;
  SECTION := '"pid"\s*:\s*' || P_ID || '\s*,\s*"id"\s*:\s*' || C_ID;
  SELECT COUNT(*)
  INTO   SCOUNT
  FROM   WX_APPENDGOODS AG
  WHERE  REGEXP_LIKE(AG.SPEC_DESCRIPTION, SECTION);
  IF SCOUNT > 0 THEN
    JO.PUT('code', -1);
    JO.PUT('pid', P_ID);
    JO.PUT('cid', C_ID);
    JO.PUT('message', '此规格已被引用，不能删除。');
    --RAISE_APPLICATION_ERROR(-20201, '此规格已被引用，不能删除。');
    RETURN JO.TO_CHAR;
  END IF;
  --RAISE_APPLICATION_ERROR(-20201, SCOUNT);
  --删除规格明细
  DELETE FROM WX_SPECITEM S
  WHERE  S.WX_SPEC_ID = P_ID
  AND    S.ID = C_ID;
  --AND    S.AD_CLIENT_ID = V_AD_CLIENT_ID;
  JO.PUT('code', 0);
  JO.PUT('pid', P_ID);
  JO.PUT('cid', C_ID);
  JO.PUT('message', '操作成功。');
  RETURN JO.TO_CHAR;
END;

/
create or replace PROCEDURE wx_appendgoods_ac(p_id IN NUMBER) AS

    -------------------------------------------------------------------------
    --add by zwm 20140401
    -------------------------------------------------------------------------
    str1 VARCHAR2(1500);
    str2 CLOB;
    jl   json_list := NEW json_list;
    jo   json;
    v_id VARCHAR2(80);
    j2  json_list := NEW json_list;
    j3  json_list := NEW json_list;
    jo2 json;
    jo3 json;
    jo4 json;
    wx_aliasid      NUMBER(10);
    v_name          VARCHAR2(200);
    v_spec          VARCHAR2(500);
    v_wx_alias_code VARCHAR2(500);
    v_qty           NUMBER(10);
    v_pricelist     NUMBER(16, 2);
    v_priceactual   NUMBER(16, 2);
    v_weight        NUMBER(16, 2);
    v_issale        CHAR(3);
		v_count         number(10);
		v_ad_client_id  number(10);
		f_sqls       varchar2(1000);
BEGIN
    SELECT t.productcategory,t.spec,t.ad_client_id
		INTO str1,v_spec,v_ad_client_id
		FROM wx_appendgoods t
		WHERE id = p_id;
		if REGEXP_LIKE(v_spec,'^[A-Za-z0-9]+$')=false then
		   raise_application_error(-20201,'商品编号只能由数字与字母组成');
		end if;
		--判断商品编号是否唯一
		select count(1)
		into v_count
		from wx_appendgoods ag
		where ag.id<>p_id
		and ag.ad_client_id=v_ad_client_id
		and ag.spec=v_spec;
		if v_count>0 then
		   raise_application_error(-20201,'商品编号已存在，请重新输入！');
		end if;
    --raise_application_error(-20014, str1);
		--更新商品类型为非积分商品
		update wx_appendgoods ag set ag.iscost='N' where ag.id=p_id;
		begin
		    jo:=json(str1);
				if jo.exist('ids') then
				   str1:=jo.get('ids').get_string;
				end if;
		    --设置商品所属分类
		    f_sqls:='update wx_productcategory pc set pc.wx_appendgoods_id='||p_id||'  where pc.id in ('||str1||')';
				execute immediate f_sqls;
				commit;
		exception when others then
		     null;
		end;
    --所属分类
    /*jl := json_list(str1);
    FOR i IN 1 .. jl.count LOOP
        jo   := json(jl.get_elem(i));
        v_id := jo.get('id').get_number;
        --raise_application_error(-20014, jo.get('id').get_number);
        INSERT INTO wx_productcategory
            (id, ad_client_id, ad_org_id, wx_appendgoods_id, creationdate,
             modifieddate, isactive, wx_itemcategoryset_id,ownerid,modifierid)
            SELECT get_sequences('WX_PRODUCTCATEGORY'), w.ad_client_id,
                   w.ad_org_id, p_id, SYSDATE, SYSDATE, 'Y', v_id,w.ownerid,w.modifierid
            FROM wx_appendgoods w
            WHERE w.id = p_id;
    END LOOP;*/
		--添加一条默认条码数据
		wx_aliasid := get_sequences('wx_alias');
		INSERT INTO wx_alias
                (id, ad_client_id, ad_org_id, wx_alias_code, wx_spec,
                 wx_specvalue, qty, pricelist, priceactual, weight, issale,lock_qty,
                 wx_appendgoods_id,wx_specid,creationdate,modifieddate,ownerid,modifierid,isdefault)
                SELECT wx_aliasid, s.ad_client_id, s.ad_org_id, wx_aliasid||dbms_random.string('x',10),
                       '均码', null, s.remainnum,s.itemunitprice, s.priceactual,
                        0, s.itemstatus,0, p_id,wx_aliasid||dbms_random.string('x',5),sysdate,sysdate,s.ownerid,s.modifierid,'Y'
                FROM wx_appendgoods s
                WHERE s.id = p_id;
    /* --商品条码
    SELECT t.spec_description
    INTO str2
    FROM wx_appendgoods t
    WHERE t.id = p_id;
    jo2 := json(str2);
    j2 := json_ext.get_json_list(jo2, 'child');
    --raise_application_error(-20014,j2.get_elem(1).to_char);
    FOR v IN 1 .. j2.count LOOP
        jo3 := json(j2.get_elem(v));
        v_wx_alias_code := jo3.get('sku').get_string;
        j3 := json_ext.get_json_list(jo3, 'space');
        --raise_application_error(-20014,j3.to_char);
        v_qty := jo3.get('inventory').get_number;
        v_pricelist := jo3.get('costprice').get_number;
        v_priceactual := jo3.get('sellprice').get_number;
        v_weight := jo3.get('wheight').get_number;
        v_issale := jo3.get('putaway').get_string;
        v_spec := NULL;
        FOR j IN 1 .. j3.count LOOP
            jo4 := json(j3.get_elem(j));
            --raise_application_error(-20014,jo4.to_char);
            v_name := jo4.get('name').get_string;
            v_spec := v_spec || '/' || v_name;
        --dbms_output.put_line(v_name);
        END LOOP;
        wx_aliasid := get_sequences('wx_alias');
        INSERT INTO wx_alias
            (id, ad_client_id, ad_org_id, wx_alias_code, wx_spec, wx_specvalue,
             qty, pricelist, priceactual, weight, issale, wx_appendgoods_id)
            SELECT wx_aliasid, s.ad_client_id, s.ad_org_id, v_wx_alias_code,
                   TRIM('/' FROM v_spec), j3.to_char, v_qty, v_pricelist,
                   v_priceactual, v_weight, v_issale, s.id
            FROM wx_appendgoods s
            WHERE s.id = p_id;
    END LOOP;*/
exception
    when no_data_found then
        raise_application_error(-20001, '请选择商品所属分类！');
END;

/
create or replace PROCEDURE wx_appendgoods_am(p_id IN NUMBER) AS

    -------------------------------------------------------------------------
    --add by zwm 20140401
    -------------------------------------------------------------------------
    str1 VARCHAR2(1500);
    str2 CLOB;
    --str3 CLOB;
    jl   json_list := NEW json_list;
    jo   json;
    v_id VARCHAR2(80);
    j2  json_list := NEW json_list;
    --j3  json_list := NEW json_list;
    --jo2 json;
    --v_sapcetemp    number(10);
    --v_spacecode           varchar2(100);
    --wx_aliasid      NUMBER(10);
    --v_name          VARCHAR2(200);
    v_spec          VARCHAR2(500);
    --v_wx_alias_code VARCHAR2(500);
    --v_qty           NUMBER(10);
		--v_lockqty       number(10);
    --v_pricelist     NUMBER(16, 2);
    --v_priceactual   NUMBER(16, 2);
    --v_weight        NUMBER(16, 2);
    --v_issale        CHAR(3);
		v_count         number(10);
		v_ad_client_id  number(10);
    v_image         varchar2(500);
    v_images        varchar2(500);
		f_default_qty  number(10);
		f_all_qty    number(10);
		f_all_count  number(10);
		f_sqls       varchar2(1000);
BEGIN
    --删除原有所属分类
    --DELETE FROM wx_productcategory t
    --WHERE t.wx_appendgoods_id = p_id;
    SELECT t.productcategory,t.spec,t.ad_client_id
    INTO str1,v_spec,v_ad_client_id
    FROM wx_appendgoods t
    WHERE id = p_id;
    --如果商品编号不为空，则判断是否唯一
		if nvl(v_spec,null) is not null then
				if REGEXP_LIKE(v_spec,'^[A-Za-z0-9]+$')=false then
					 raise_application_error(-20201,'商品编号只能由数字与字母组成');
				end if;
				--判断商品编号是否唯一
				select count(1)
				into v_count
				from wx_appendgoods ag
				where ag.id<>p_id
				and ag.ad_client_id=v_ad_client_id
				and ag.spec=v_spec;
				if v_count>0 then
					 raise_application_error(-20201,'商品编号已存在，请重新输入！');
				end if;
		end if;
    --raise_application_error(-20014, str1);
    begin
		    jo:=json(str1);
				if jo.exist('ids') then
				   str1:=jo.get('ids').get_string;
				end if;
		    --设置商品所属分类
		    f_sqls:='update wx_productcategory pc set pc.wx_appendgoods_id='||p_id||'  where pc.id in ('||str1||')';
				execute immediate f_sqls;
				commit;
		exception when others then
		     null;
		end;
    /*jl := json_list(str1);
    FOR i IN 1 .. jl.count LOOP
        jo := json(jl.get_elem(i));
        v_id := jo.get('id').get_number;
        --raise_application_error(-20014, jo.get('id').get_number);
        INSERT INTO wx_productcategory
            (id, ad_client_id, ad_org_id, wx_appendgoods_id, creationdate,
             modifieddate, isactive, wx_itemcategoryset_id,modifierid)
            SELECT get_sequences('WX_PRODUCTCATEGORY'), w.ad_client_id,
                   w.ad_org_id, p_id, SYSDATE, SYSDATE, 'Y', v_id,w.modifierid
            FROM wx_appendgoods w
            WHERE w.id = p_id;
    END LOOP;*/
		--修改默认库存的金额与数量
		update wx_alias a set (a.qty,a.pricelist,a.priceactual)
		                =(select ag.remainnum,ag.itemunitprice,ag.priceactual from wx_appendgoods ag where ag.id=p_id)
		where a.wx_appendgoods_id=p_id
		and   a.isdefault='Y';
		--查询默认条码库存数量
		select nvl(sum(nvl(a.qty,0)),0)
		into f_default_qty
		from wx_alias a
		where a.wx_appendgoods_id=p_id
		and a.isdefault='Y';
		--查询所有条码库存
		select nvl(sum(nvl(a.qty,0)),0),count(1)
		into f_all_qty,f_all_count
		from wx_alias a
		where a.wx_appendgoods_id=p_id
		and a.isdefault='N';
		--修改商品库存
		update wx_appendgoods ag set ag.remainnum=case when f_all_count>0 then f_all_qty else f_default_qty end
		where ag.id=p_id;
    --存储图片路径
   select t.productpics
    into str2
    from WX_APPENDGOODS t
    where t.id = p_id;
    IF str2 IS NOT NULL THEN
      --str3 := '['||str2||']';
      j2 :=json_list(str2);
       FOR i IN 1 .. j2.count LOOP
            v_image:=j2.get_elem(i).get_string;
           if v_image IS NOT NULL THEN
           v_images:='/servlets/userfolder/WX_APPENDGOODS/'||v_image;
             END if;
           INSERT INTO wx_pdt_image
           (id,ad_client_id,ad_org_id,wx_appendgoods_id,image,ownerid,modifierid,creationdate,modifieddate,isactive)
           select get_sequences('Wx_Pdt_Image'),s.ad_client_id,s.ad_org_id,s.id,v_images,s.ownerid,s.modifierid,sysdate,sysdate, 'Y'
            FROM wx_appendgoods s
             where s.id= p_id;
              END LOOP;
       END if;
		--商品条码
   /* SELECT t.spec_description
    INTO str2
    FROM wx_appendgoods t
    WHERE t.id = p_id;
    IF str2 IS NOT NULL THEN
        jo2 := json(str2);
        j2 := json_ext.get_json_list(jo2, 'child');
        --raise_application_error(-20014,j2.get_elem(1).to_char);
        FOR v IN 1 .. j2.count LOOP
            jo3 := json(j2.get_elem(v));
            v_wx_alias_code := jo3.get('sku').get_string;
						if nvl(v_wx_alias_code,'')='' then
						   raise_application_error(-20201,'货号不能为空！');
						end if;
						if regexp_like(v_wx_alias_code,'^[A-Za-z0-9]+$')=false then
						   raise_application_error(-20201,'货号只能由数字与字母组成');
						end if;
						--判断条码是否存在
						select count(1)
						into v_count
						from wx_alias a
						where a.ad_client_id=v_ad_client_id
						and a.wx_alias_code=v_wx_alias_code;
						if v_count>0 then
						   raise_application_error(-20201,'货号已存在，请重新输入！');
						end if;
            j3 := json_ext.get_json_list(jo3, 'space');
            v_qty := jo3.get('inventory').get_number;
						v_lockqty:=jo3.get('lockinventory').get_number;
            v_pricelist := jo3.get('costprice').get_number;
            v_priceactual := jo3.get('sellprice').get_number;
            v_weight := jo3.get('wheight').get_number;
            v_issale := jo3.get('putaway').get_string;
            v_spec := NULL;
						v_spacecode:='';
            FOR j IN 1 .. j3.count LOOP
                jo4 := json(j3.get_elem(j));
                --raise_application_error(-20014,jo4.to_char);
                v_name := jo4.get('name').get_string;
                v_spec := v_spec || '/' || v_name;
                v_sapcetemp:=jo4.get('id').get_number;
								if j>1 then
							     v_spacecode:=v_spacecode||'_';
						    end if;
								v_spacecode:=v_spacecode||v_sapcetemp;
            --dbms_output.put_line(v_name);
            END LOOP;
            wx_aliasid := get_sequences('wx_alias');
            INSERT INTO wx_alias
                (id, ad_client_id, ad_org_id, wx_alias_code, wx_spec,
                 wx_specvalue, qty, pricelist, priceactual, weight, issale,lock_qty,
                 wx_appendgoods_id,wx_specid,creationdate,modifieddate,ownerid,modifierid)
                SELECT wx_aliasid, s.ad_client_id, s.ad_org_id, v_wx_alias_code,
                       TRIM('/' FROM v_spec), j3.to_char, v_qty, v_pricelist,
                       v_priceactual, v_weight, v_issale,v_lockqty, s.id,v_spacecode,sysdate,sysdate,s.ownerid,s.modifierid
                FROM wx_appendgoods s
                WHERE s.id = p_id;
        END LOOP;
    END IF;*/
END;

/
create or replace PROCEDURE wx_v_cost_appendgoods_ac(p_id IN NUMBER) AS

    -------------------------------------------------------------------------
    --add by zwm 20140401
    -------------------------------------------------------------------------
    str1 VARCHAR2(1500);
    str2 CLOB;
    jl   json_list := NEW json_list;
    jo   json;
    v_id VARCHAR2(80);
    j2  json_list := NEW json_list;
    --j3  json_list := NEW json_list;
    --jo2 json;
    --jo3 json;
    --jo4 json;
    wx_aliasid      NUMBER(10);
    --v_name          VARCHAR2(200);
    v_spec          VARCHAR2(500);
    --v_wx_alias_code VARCHAR2(500);
    --v_qty           NUMBER(10);
    --v_pricelist     NUMBER(16, 2);
    --v_priceactual   NUMBER(16, 2);
    --v_weight        NUMBER(16, 2);
    --v_issale        CHAR(3);
    v_count         number(10);
    v_ad_client_id  number(10);
    v_image         varchar2(500);
    v_images        varchar2(500);
		f_sqls       varchar2(1000);
BEGIN
    SELECT t.productcategory,t.spec,t.ad_client_id
    INTO str1,v_spec,v_ad_client_id
    FROM wx_appendgoods t
    WHERE id = p_id;
    if REGEXP_LIKE(v_spec,'^[A-Za-z0-9]+$')=false then
       raise_application_error(-20201,'商品编号只能由数字与字母组成');
    end if;
    --判断商品编号是否唯一
    select count(1)
    into v_count
    from wx_appendgoods ag
    where ag.id<>p_id
    and ag.ad_client_id=v_ad_client_id
    and ag.spec=v_spec;
    if v_count>0 then
       raise_application_error(-20201,'商品编号已存在，请重新输入！');
    end if;
    --raise_application_error(-20014, str1);
		--更新商品类型为积分商品
		update wx_appendgoods ag set ag.iscost='Y',ag.itemunitprice=ag.priceactual where ag.id=p_id;
		begin
		    jo:=json(str1);
				if jo.exist('ids') then
				   str1:=jo.get('ids').get_string;
				end if;
		    --设置商品所属分类
		    f_sqls:='update wx_productcategory pc set pc.wx_appendgoods_id='||p_id||'  where pc.id in ('||str1||')';
				execute immediate f_sqls;
				commit;
		exception when others then
		     null;
		end;
    /*--所属分类
    jl := json_list(str1);
    FOR i IN 1 .. jl.count LOOP
        jo   := json(jl.get_elem(i));
        v_id := jo.get('id').get_number;
        --raise_application_error(-20014, jo.get('id').get_number);
        INSERT INTO wx_productcategory
            (id, ad_client_id, ad_org_id, wx_appendgoods_id, creationdate,
             modifieddate, isactive, wx_itemcategoryset_id,ownerid,modifierid)
            SELECT get_sequences('WX_PRODUCTCATEGORY'), w.ad_client_id,
                   w.ad_org_id, p_id, SYSDATE, SYSDATE, 'Y', v_id,w.ownerid,w.modifierid
            FROM wx_appendgoods w
            WHERE w.id = p_id;
    END LOOP;*/
    --添加一条默认条码数据
    wx_aliasid := get_sequences('wx_alias');
    INSERT INTO wx_alias
                (id, ad_client_id, ad_org_id, wx_alias_code, wx_spec,
                 wx_specvalue, qty, pricelist, priceactual, weight, issale,lock_qty,
                 wx_appendgoods_id,wx_specid,creationdate,modifieddate,ownerid,modifierid,isdefault)
                SELECT wx_aliasid, s.ad_client_id, s.ad_org_id, wx_aliasid||dbms_random.string('x',10),
                       '均码', null, s.remainnum,s.itemunitprice, s.priceactual,
                        0, s.itemstatus,0, p_id,wx_aliasid||dbms_random.string('x',5),sysdate,sysdate,s.ownerid,s.modifierid,'Y'
                FROM wx_appendgoods s
                WHERE s.id = p_id;
     --存储图片路径
   select t.productpics
    into str2
    from WX_APPENDGOODS t
    where t.id = p_id;
    IF str2 IS NOT NULL THEN
      --str3 := '['||str2||']';
      j2 :=json_list(str2);
       FOR i IN 1 .. j2.count LOOP
            v_image:=j2.get_elem(i).get_string;
           if v_image IS NOT NULL THEN
           v_images:='/servlets/userfolder/WX_APPENDGOODS/'||v_image;
             END if;
           INSERT INTO wx_pdt_image
           (id,ad_client_id,ad_org_id,wx_appendgoods_id,image,ownerid,modifierid,creationdate,modifieddate,isactive)
           select get_sequences('Wx_Pdt_Image'),s.ad_client_id,s.ad_org_id,s.id,v_images,s.ownerid,s.modifierid,sysdate,sysdate, 'Y'
            FROM wx_appendgoods s
             where s.id= p_id;
              END LOOP;
       END if;
    /* --商品条码
    SELECT t.spec_description
    INTO str2
    FROM wx_appendgoods t
    WHERE t.id = p_id;
    jo2 := json(str2);
    j2 := json_ext.get_json_list(jo2, 'child');
    --raise_application_error(-20014,j2.get_elem(1).to_char);
    FOR v IN 1 .. j2.count LOOP
        jo3 := json(j2.get_elem(v));
        v_wx_alias_code := jo3.get('sku').get_string;
        j3 := json_ext.get_json_list(jo3, 'space');
        --raise_application_error(-20014,j3.to_char);
        v_qty := jo3.get('inventory').get_number;
        v_pricelist := jo3.get('costprice').get_number;
        v_priceactual := jo3.get('sellprice').get_number;
        v_weight := jo3.get('wheight').get_number;
        v_issale := jo3.get('putaway').get_string;
        v_spec := NULL;
        FOR j IN 1 .. j3.count LOOP
            jo4 := json(j3.get_elem(j));
            --raise_application_error(-20014,jo4.to_char);
            v_name := jo4.get('name').get_string;
            v_spec := v_spec || '/' || v_name;
        --dbms_output.put_line(v_name);
        END LOOP;
        wx_aliasid := get_sequences('wx_alias');
        INSERT INTO wx_alias
            (id, ad_client_id, ad_org_id, wx_alias_code, wx_spec, wx_specvalue,
             qty, pricelist, priceactual, weight, issale, wx_appendgoods_id)
            SELECT wx_aliasid, s.ad_client_id, s.ad_org_id, v_wx_alias_code,
                   TRIM('/' FROM v_spec), j3.to_char, v_qty, v_pricelist,
                   v_priceactual, v_weight, v_issale, s.id
            FROM wx_appendgoods s
            WHERE s.id = p_id;
    END LOOP;*/
exception
    when no_data_found then
        raise_application_error(-20001, '请选择商品所属分类！');
END;

/
create or replace PROCEDURE wx_v_cost_appendgoods_am(p_id IN NUMBER) AS

    -------------------------------------------------------------------------
    --add by zwm 20140401
    -------------------------------------------------------------------------
    str1 VARCHAR2(1500);
    str2 CLOB;
    jl   json_list := NEW json_list;
    jo   json;
    v_id VARCHAR2(80);
    j2  json_list := NEW json_list;
    --j3  json_list := NEW json_list;
    --jo2 json;
    --jo3 json;
    --jo4 json;
    --v_sapcetemp    number(10);
    --v_spacecode           varchar2(100);
    --wx_aliasid      NUMBER(10);
    --v_name          VARCHAR2(200);
    v_spec          VARCHAR2(500);
    --v_wx_alias_code VARCHAR2(500);
    --v_qty           NUMBER(10);
    --v_lockqty       number(10);
    --v_pricelist     NUMBER(16, 2);
    --v_priceactual   NUMBER(16, 2);
    --v_weight        NUMBER(16, 2);
    --v_issale        CHAR(3);
    v_count         number(10);
    v_ad_client_id  number(10);
    f_default_qty  number(10);
    f_all_qty    number(10);
    f_all_count  number(10);
    v_image         varchar2(500);
    v_images        varchar2(500);
		f_sqls       varchar2(1000);
BEGIN
    --删除原有所属分类
    --DELETE FROM wx_productcategory t
    --WHERE t.wx_appendgoods_id = p_id;
    SELECT t.productcategory,t.spec,t.ad_client_id
    INTO str1,v_spec,v_ad_client_id
    FROM wx_appendgoods t
    WHERE id = p_id;
    --如果商品编号不为空，则判断是否唯一
    if nvl(v_spec,null) is not null then
        if REGEXP_LIKE(v_spec,'^[A-Za-z0-9]+$')=false then
           raise_application_error(-20201,'商品编号只能由数字与字母组成');
        end if;
        --判断商品编号是否唯一
        select count(1)
        into v_count
        from wx_appendgoods ag
        where ag.id<>p_id
        and ag.ad_client_id=v_ad_client_id
        and ag.spec=v_spec;
        if v_count>0 then
           raise_application_error(-20201,'商品编号已存在，请重新输入！');
        end if;
    end if;
		begin
		    jo:=json(str1);
				if jo.exist('ids') then
				   str1:=jo.get('ids').get_string;
				end if;
		    --设置商品所属分类
		    f_sqls:='update wx_productcategory pc set pc.wx_appendgoods_id='||p_id||'  where pc.id in ('||str1||')';
				execute immediate f_sqls;
				commit;
		exception when others then
		     null;
		end;
    --raise_application_error(-20014, str1);
    /*jl := json_list(str1);
    FOR i IN 1 .. jl.count LOOP
        jo := json(jl.get_elem(i));
        v_id := jo.get('id').get_number;
        --raise_application_error(-20014, jo.get('id').get_number);
        INSERT INTO wx_productcategory
            (id, ad_client_id, ad_org_id, wx_appendgoods_id, creationdate,
             modifieddate, isactive, wx_itemcategoryset_id,modifierid)
            SELECT get_sequences('WX_PRODUCTCATEGORY'), w.ad_client_id,
                   w.ad_org_id, p_id, SYSDATE, SYSDATE, 'Y', v_id,w.modifierid
            FROM wx_appendgoods w
            WHERE w.id = p_id;
    END LOOP;*/
        --查询默认条码库存数量
    select nvl(sum(nvl(a.qty,0)),0)
    into f_default_qty
    from wx_alias a
    where a.wx_appendgoods_id=p_id
    and a.isdefault='Y';
    --查询所有条码库存
    select nvl(sum(nvl(a.qty,0)),0),count(1)
    into f_all_qty,f_all_count
    from wx_alias a
    where a.wx_appendgoods_id=p_id
    and a.isdefault='N';
    --修改商品库存
    update wx_appendgoods ag set ag.remainnum=case when f_all_count>0 then f_all_qty else f_default_qty end,ag.itemunitprice=ag.priceactual
    where ag.id=p_id;
      --存储图片路径
   select t.productpics
    into str2
    from WX_APPENDGOODS t
    where t.id = p_id;
    IF str2 IS NOT NULL THEN
      --str3 := '['||str2||']';
      j2 :=json_list(str2);
       FOR i IN 1 .. j2.count LOOP
            v_image:=j2.get_elem(i).get_string;
           if v_image IS NOT NULL THEN
           v_images:='/servlets/userfolder/WX_APPENDGOODS/'||v_image;
             END if;
           INSERT INTO wx_pdt_image
           (id,ad_client_id,ad_org_id,wx_appendgoods_id,image,ownerid,modifierid,creationdate,modifieddate,isactive)
           select get_sequences('Wx_Pdt_Image'),s.ad_client_id,s.ad_org_id,s.id,v_images,s.ownerid,s.modifierid,sysdate,sysdate, 'Y'
            FROM wx_appendgoods s
             where s.id= p_id;
              END LOOP;
       END if;
    --商品条码
   /* SELECT t.spec_description
    INTO str2
    FROM wx_appendgoods t
    WHERE t.id = p_id;
    IF str2 IS NOT NULL THEN
        jo2 := json(str2);
        j2 := json_ext.get_json_list(jo2, 'child');
        --raise_application_error(-20014,j2.get_elem(1).to_char);
        FOR v IN 1 .. j2.count LOOP
            jo3 := json(j2.get_elem(v));
            v_wx_alias_code := jo3.get('sku').get_string;
            if nvl(v_wx_alias_code,'')='' then
               raise_application_error(-20201,'货号不能为空！');
            end if;
            if regexp_like(v_wx_alias_code,'^[A-Za-z0-9]+$')=false then
               raise_application_error(-20201,'货号只能由数字与字母组成');
            end if;
            --判断条码是否存在
            select count(1)
            into v_count
            from wx_alias a
            where a.ad_client_id=v_ad_client_id
            and a.wx_alias_code=v_wx_alias_code;
            if v_count>0 then
               raise_application_error(-20201,'货号已存在，请重新输入！');
            end if;
            j3 := json_ext.get_json_list(jo3, 'space');
            v_qty := jo3.get('inventory').get_number;
            v_lockqty:=jo3.get('lockinventory').get_number;
            v_pricelist := jo3.get('costprice').get_number;
            v_priceactual := jo3.get('sellprice').get_number;
            v_weight := jo3.get('wheight').get_number;
            v_issale := jo3.get('putaway').get_string;
            v_spec := NULL;
            v_spacecode:='';
            FOR j IN 1 .. j3.count LOOP
                jo4 := json(j3.get_elem(j));
                --raise_application_error(-20014,jo4.to_char);
                v_name := jo4.get('name').get_string;
                v_spec := v_spec || '/' || v_name;
                v_sapcetemp:=jo4.get('id').get_number;
                if j>1 then
                   v_spacecode:=v_spacecode||'_';
                end if;
                v_spacecode:=v_spacecode||v_sapcetemp;
            --dbms_output.put_line(v_name);
            END LOOP;
            wx_aliasid := get_sequences('wx_alias');
            INSERT INTO wx_alias
                (id, ad_client_id, ad_org_id, wx_alias_code, wx_spec,
                 wx_specvalue, qty, pricelist, priceactual, weight, issale,lock_qty,
                 wx_appendgoods_id,wx_specid,creationdate,modifieddate,ownerid,modifierid)
                SELECT wx_aliasid, s.ad_client_id, s.ad_org_id, v_wx_alias_code,
                       TRIM('/' FROM v_spec), j3.to_char, v_qty, v_pricelist,
                       v_priceactual, v_weight, v_issale,v_lockqty, s.id,v_spacecode,sysdate,sysdate,s.ownerid,s.modifierid
                FROM wx_appendgoods s
                WHERE s.id = p_id;
        END LOOP;
    END IF;*/
END;

/
create or replace FUNCTION get_pathurl(pid IN number, tabname in varchar2)

    RETURN varchar2 AS
    v_purl VARCHAR2(500);
BEGIN
    if upper(tabname) = 'WX_ARTICLECATEGORY' then
        select 'http://' || e.domain || replace(g.purl, '@ID@', t.id)
        into v_purl
        from WX_ARTICLECATEGORY t, wx_v_jumpurlpath g, web_client e
        where g.id = 14+t.ad_client_id and t.ad_client_id = e.ad_client_id and t.id = pid
        and g.ad_client_id=t.ad_client_id;
    elsif upper(tabname) = 'WX_ITEMCATEGORYSET' then
        select 'http://' || e.domain || replace(g.purl, '@ID@', t.id)
        into v_purl
        from WX_ITEMCATEGORYSET t, wx_v_jumpurlpath g, web_client e
        where g.id = 3+t.ad_client_id and t.ad_client_id = e.ad_client_id and t.id = pid
         and g.ad_client_id=t.ad_client_id;
    elsif upper(tabname) = 'WX_V_APPENDGOODS' then
        select 'http://' || e.domain || replace(g.url, '@ID@', t.id) as purl
        into v_purl
        from WX_APPENDGOODS t，WX_JUMPURL g, web_client e
        where t.ad_client_id = e.ad_client_id and g.id = 8 and t.id = pid;
     elsif upper(tabname) = 'WX_COST_APPENDGOODS' then
        select 'http://' || e.domain || replace(g.url, '@ID@', t.id) as purl
        into v_purl
        from WX_APPENDGOODS t，WX_JUMPURL g, web_client e
        where t.ad_client_id = e.ad_client_id and g.id = 41 and t.id = pid;
    elsif upper(tabname) = 'WX_V_ISSUEARTICLE' then
        select 'http://' || e.domain || replace(g.url, '@ID@', t.id) as"URL"
        into v_purl
        from WX_ISSUEARTICLE t, web_client e, wx_jumpurl g
        where t.ad_client_id = e.ad_client_id and g.id = 16 and t.id = pid;
    elsif upper(tabname) = 'WX_SETCOLUMN' or upper(tabname) = 'WX_V1_SETCOLUMN' or
          upper(tabname) = 'WX_V_SETCOLUMN' then
        select 'http://' || e.domain ||
                replace(replace(nvl(g.url, t.objid), '@ID@', t.objid),
                        '@' || g.tmp_class || '@',
                        get_classtmp(g.tmp_class, t.ad_client_id)) as fullurl
        into v_purl
        from WX_SETCOLUMN t，WX_JUMPURL g, web_client e
        where t.fromid = g.id(+) and t.ad_client_id = e.ad_client_id and
              t.id = pid;
    end if;
    RETURN v_purl;
END;

/
create or replace procedure wx_regisset_am(p_id in number) as

    ------------------------------------------------------------
    --add by zt 20141008
    ------------------------------------------------------------
  v_ad_client_id NUMBER(10);
	v_count NUMBER(10);
  v_count2 NUMBER(10);
begin
  select t.ad_client_id into v_ad_client_id from WX_REGISSET t where t.id = p_id;
  select count(*) into v_count from wx_invitation t where t.ad_client_id = v_ad_client_id and t.wx_regisset_id = p_id and to_number(t.endtime-sysdate)<=0;
  if v_count >= 1 then
     raise_application_error(-20201,'只能修改还未结束的邀请函关联的报名模板！');
  end if;
  select count(1) into v_count2 from WX_REGISRECORD t where t.wx_regisset_id = p_id and t.ad_client_id = v_ad_client_id;
  if v_count2 >= 1 then
     raise_application_error(-20201,'报名模板已经被使用，不允许修改！');
  end if;
end;

/
create or replace procedure wx_regisset_bd(p_id in number) as

    ------------------------------------------------------------
    --add by zt 20141008
    ------------------------------------------------------------
    v_ad_client_id NUMBER(10);
  v_count NUMBER(10);
  v_count1 NUMBER(10);
  v_count2 NUMBER(10);
begin
  select t.ad_client_id into v_ad_client_id from WX_REGISSET t where t.id = p_id;
  select count(1) into v_count from WX_INVITATION t where t.wx_regisset_id = p_id and t.ad_client_id = v_ad_client_id;
  if v_count >= 1 then
     raise_application_error(-20201,'只能删除未被引用的报名模板');
  end if;
  select count(1) into v_count1 from WX_MAGAZINEANCHOR t where t.fromid='WX_REGISSET' and t.objectid = p_id and t.ad_client_id = v_ad_client_id;
  if v_count1 >= 1 then
     raise_application_error(-20201,'只能删除未被引用的报名模板');
  end if;
  select count(1) into v_count2 from WX_REGISRECORD t where t.wx_regisset_id = p_id and t.ad_client_id = v_ad_client_id;
  if v_count2 >= 1 then
     raise_application_error(-20201,'只能删除未被引用的报名模板');
  end if;
  delete from WX_REGISSET t where t.id = p_id and t.ad_client_id = v_ad_client_id;
end;

/
create or replace function wx_regiscontrol_getjson

	return clob is
	f_result_clob clob;
	f_rqcodemessage_ja json_list;
	f_sql varchar2(1000);
begin
	f_sql:='select name,key,type,checktype,optional,required,ifmodify from WX_REGISCONTROL';
begin
	f_rqcodemessage_ja:=json_dyn.executeList(f_sql);
	exception when others then
		f_rqcodemessage_ja:=new json_list();
	end;
	f_result_clob:=empty_clob();
	dbms_lob.createtemporary(f_result_clob,true);
	f_rqcodemessage_ja.to_clob(f_result_clob,true);
  return f_result_clob;
end;

/
create or replace PROCEDURE WEB_CLIENT_AM

  (
    p_id IN NUMBER)
AS
  -------------------------------------------------------------------------
  --add by zt 20140904
  --1 当向公司信息表更新数据，同时更新wx_reguser,users,user_@lportal
  -------------------------------------------------------------------------
  v_ad_client_id NUMBER(10);
  v_contactname varchar(100);
  v_nickname varchar(100);
  v_company varchar(100);
  v_address  varchar(100);
  v_contactphone varchar(100);
  v_wxnum varchar(100);
  v_email varchar(100);
  v_description varchar(100);
  v_greeting varchar(100);
BEGIN
  select w.ad_client_id,w.contactname,w.nickname,w.company,w.address,w.wxnum,w.email,w.contactphone into v_ad_client_id,v_contactname,v_nickname,v_company,v_address,v_wxnum,v_email,v_contactphone from web_client w where w.id = p_id;
  v_description := v_company || '网管';
  v_greeting := '欢迎' || nvl(v_nickname,v_contactname);
  update wx_reguser w set w.username = v_contactname,w.company = v_company,w.address = v_address where w.wxappid = v_wxnum and w.phonenumber = v_contactphone;
  update users w set  w.truename = v_contactname,w.description = v_description where w.ad_client_id = v_ad_client_id;
  update user_@lportal w set w.greeting = v_greeting where w.emailaddress = v_email;
END;

/
create or replace FUNCTION wx_notify_$r_aud(p_user_id IN NUMBER,

                                                 p_str IN VARCHAR2)
    RETURN VARCHAR2 IS
    ---------------------------------------------------------------
    --add by zwm 2010515
    --消息增删改
    ---------------------------------------------------------------
    str1     VARCHAR2(4000);
    jos      json; -- 传入的json值
    jos3     json; -- 图文json
    jos4     json; --得到图文jos3相应的（key）的（Value）值
    jos_lis2 json_list := NEW json_list;--图文jos3的key值
  v_msgtype     VARCHAR2(200);
	v_title VARCHAR(500);
	v_content     CLOB;
	v_wx_media_id NUMBER(10);
	v_url         VARCHAR(100);
	v_count       NUMBER(10);--图文个数
	v_gourl       VARCHAR(100);
	v_hurl        VARCHAR(100);
	v_groupid     NUMBER(10);
  v_ad_clientid NUMBER(10);
  v_orginalcontent CLOB;
	v_openId VARCHAR2(200);--用户opendId
	v_openIdList clob;--用户集合opendId
	v_type VARCHAR2(20); --消息类型 群发（mass） 单发 （single）
  v_reply_id NUMBER(10);--回复消息id
  v_openIdTempID NUMBER(10);--临时存放VIP信息的记录id
	--图文信息
    v_title1               VARCHAR(500);
    v_content1             CLOB;
    v_wx_media_id1         NUMBER(10);
    v_url1                 VARCHAR2(1000);
    v_objid1               VARCHAR2(1000);
	v_fromid1              NUMBER(10);
    v_wx_notifyid     NUMBER(10);
    v_wx_notifyitemid NUMBER(10);
    v_urlcontent           VARCHAR2(1500);
    v_sort                 number(10);
	--json的 key值
	v_key         VARCHAR2(100);
	--返回WX_NOTIFYMEMBER记录id
	v_wx_nofitymemberid NUMBER(10);
    err_msg VARCHAR2(1000);
    pjo     json := NEW json();--错误信息
    --PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    jos := json(p_str);
    v_msgtype := jos.get('msgtype').get_string;
		v_title := jos.get('title').get_string;
		v_content := jos.get('content').get_string;
		v_wx_media_id := jos.get('wx_media_id').get_number;
		v_url := jos.get('url').get_string;
		v_count := jos.get('count').get_number;
		v_gourl := jos.get('gourl').get_string;
		v_hurl := jos.get('hurl').get_string;
		v_groupid := jos.get('groupid').get_number;
		v_ad_clientid := jos.get('ad_client_id').get_number;
		v_urlcontent := jos.get('urlcontent').get_string;
		v_openId :=  jos.get('openId').get_string;
		v_type :=  jos.get('type').get_string;
		v_reply_id:= jos.get('replyid').get_number;
		v_orginalcontent :=jos.get('orginalcontent').get_string;
    v_wx_notifyid := get_sequences('wx_notify');
    IF v_groupid=0 or nvl(v_groupid,'')='' or v_groupid is null THEN
       v_groupid:= v_wx_notifyid;
    END IF;
    IF v_msgtype <> '图文' THEN
        DELETE FROM WX_NOTIFY t
        WHERE t.ad_client_id = v_ad_clientid
        AND t.groupid = v_groupid;
    ELSE
        DELETE FROM WX_NOTIFY t
        WHERE t.ad_client_id = v_ad_clientid
        AND t.groupid = v_groupid;
        DELETE FROM WX_NOITFYITEM t1
        WHERE t1.ad_client_id = v_ad_clientid
        AND t1.groupid = v_groupid;
    END IF;
    begin
				IF v_msgtype <> '图文' THEN
						INSERT INTO WX_NOTIFY
								(id, ad_client_id,
								 msgtype, title,
								 content, wx_media_id, url, COUNT, gourl, hurl,
								 groupid, creationdate, urlcontent, orginalcontent)
						VALUES
								(v_wx_notifyid, decode(v_ad_clientid, 0, NULL, v_ad_clientid),
								 (CASE v_msgtype WHEN '文本' THEN 1 WHEN '图片' THEN 2 WHEN '语音' THEN 3 WHEN '视频' THEN 4 WHEN '音乐' THEN 5 WHEN '图文' THEN 6 WHEN '链接' then 7 ELSE NULL END),
								 v_title, v_content, decode(v_wx_media_id, 0, NULL, v_wx_media_id),
								 v_url, v_count, v_gourl, v_hurl,
								 decode(v_groupid, 0, NULL, v_groupid), SYSDATE,
								 v_urlcontent,v_orginalcontent);
				ELSE
				INSERT INTO wx_notify
					(id, ad_client_id,
					 msgtype, title,
					 content, wx_media_id, url, COUNT, gourl, hurl,
					 groupid, creationdate, urlcontent)
				VALUES
					(v_wx_notifyid,
					 decode(v_ad_clientid, 0, NULL, v_ad_clientid),
					 (CASE v_msgtype WHEN '图文' THEN 6 ELSE NULL END), v_title,
					 v_content, decode(v_wx_media_id, 0, NULL, v_wx_media_id), v_url,
					 v_count, v_gourl, v_hurl,
					 decode(v_groupid, 0, NULL, v_groupid),
					 SYSDATE, v_urlcontent);
				--v_wx_notifyid := get_sequences('wx_notify');
						--对应插入内容
						jos3 := json_ext.get_json(jos, 'tuwen');
						jos_lis2 := jos3.get_keys;
						FOR v IN 1 .. jos_lis2.count LOOP
								v_key := jos_lis2.get_elem(v).get_string();
								jos4 := json_ext.get_json(jos3, v_key);
								v_title1 := jos4.get('title1').get_string;
								v_content1 := jos4.get('content1').get_string;
								v_url1 := jos4.get('url1').get_string;
								v_objid1 := jos4.get('objid').get_string;
								v_fromid1 := jos4.get('fromid').get_number;
								v_sort:=jos4.get('sort').get_number;
								INSERT INTO WX_NOITFYITEM
										(id, ad_client_id,
										 title,
										 sort,
										 content, wx_media_id, url, gourl, groupid, creationdate, objid,
										 fromid)
								VALUES
										(get_sequences('WX_NOITFYITEM'), v_ad_clientid, v_title1,v_sort,
										 v_content1, NULL, v_url1, NULL, v_groupid, SYSDATE, v_objid1,
										 v_fromid1);
						END LOOP;
				END IF;
			--插入记录wx_notifymember
			IF v_type <> 'mass' THEN
				wx_notify_ac(v_wx_notifyid,v_openId,0,NULL,v_reply_id);
			ELSE
        v_openIdTempID := jos.get('opendIdList').get_number;
        select t.massopenid into v_openIdList from WX_NOTIFYTEMP t where t.ad_client_id = v_ad_clientid  and t.id= v_openIdTempID;
				--v_openIdList :=  jos.get('opendIdList').get_string;
				wx_notify_ac(v_wx_notifyid,NULL,1,v_openIdList,NULL);
			END IF;
				--COMMIT;
			select id INTO v_wx_nofitymemberid from wx_notifymember where ad_client_id = v_ad_clientid and wx_notify_id = v_wx_notifyid;
				pjo.put('code', 0);
				pjo.put('message','操作成功');
				pjo.put('memberid',v_wx_nofitymemberid);
		exception when others then
				pjo.put('code', -1);
				pjo.put('message',SQLERRM);
		end;
    /*EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; -- 回滾
        --END;*/
    RETURN pjo.to_char;
END;

/
create or replace PROCEDURE wx_address_acm(p_id IN NUMBER) AS

    -------------------------------------------------------------------------
    --add by zwm 20140409
    --modify by zt 20141030
    --1 判断只能有一个默认地址
    -------------------------------------------------------------------------
    v_count        NUMBER(10);
    v_ad_client_id NUMBER(10);
    v_vip_id       NUMBER(10);
    v_isaddress    NUMBER(2);
BEGIN
    select t.ad_client_id, t.wx_vip_id, t.isaddress
    into v_ad_client_id, v_vip_id, v_isaddress
    from wx_address t
    where t.id = p_id;
    select count(*)
    into v_count
    from wx_address t
    where t.ad_client_id = v_ad_client_id and t.wx_vip_id = v_vip_id and
          t.id <> p_id;
    --raise_application_error(-20201,'测试地址默认值' || v_isaddress);
    IF v_isaddress = 1 and v_count = 0 THEN
        update wx_address t
        set t.isaddress = 2
        where t.id = p_id and t.wx_vip_id = v_vip_id and
              t.ad_client_id = v_ad_client_id;
    ELSIF v_isaddress = 2 and v_count <> 0 THEN
        update wx_address t
        set t.isaddress = 1
        where t.id <> p_id and t.wx_vip_id = v_vip_id and
              t.ad_client_id = v_ad_client_id;
    END IF;
END;

/
create or replace PROCEDURE wx_address_bd(p_id IN NUMBER) AS

    -------------------------------------------------------------------------
    --add by zt 20141030
    --1 删除默认地址时，修改最新地址为默认地址
    -------------------------------------------------------------------------
    v_count        NUMBER(10);
    v_ad_client_id NUMBER(10);
    v_vip_id       NUMBER(10);
    v_isaddress    NUMBER(2);
    v_p_id         NUMBER(10);
BEGIN
    select t.ad_client_id, t.wx_vip_id, t.isaddress
    into v_ad_client_id, v_vip_id, v_isaddress
    from wx_address t
    where t.id = p_id;
    select count(*)
    into v_count
    from wx_address t
    where t.ad_client_id = v_ad_client_id and t.wx_vip_id = v_vip_id and
          t.id <> p_id;
    IF v_isaddress = 2 and v_count <> 0 THEN
        select w.id
        into v_p_id
        from (select *
               from wx_address t
               where t.id <> p_id and t.wx_vip_id = v_vip_id and
                     t.ad_client_id = v_ad_client_id
               order by id desc) w
        where rownum = 1;
        update wx_address t
        set t.isaddress = 2
        where t.id = v_p_id and t.wx_vip_id = v_vip_id and
              t.ad_client_id = v_ad_client_id;
    END IF;
END;

/
create or replace PROCEDURE wx_order_acm(p_id IN NUMBER) AS

    -------------------------------------------------------------------------
    --add by zwm 20140402
    --1 如果是特殊活动类型单据，必须填写对应的销售活动
    --2 刷新团购单明细数据
    --3 更新单据状态为待支付，提交之后为已支付
    -------------------------------------------------------------------------
    v_groupon_id NUMBER(10);
    v_userid     NUMBER(10);
    v_order_id   NUMBER(10);
    v_ordertype  CHAR(3);
		v_couponemploy_id  number(10);
		v_coupon_money          number(10,2):=0;
		v_isUseCoupon   char(1):='N';
		v_isOverdue     char(1):='N';--是否过期
		v_coupon_id  NUMBER(10);
		v_coupon_count number(10);
		v_client_id     number(10);
    v_address varchar(250); --订单收货地址
    v_address_id number(10);--订单收货外键
BEGIN
    SELECT a.ad_client_id,a.wx_groupon_id, a.ordertype, a.id, a.ownerid,nvl(a.wx_couponemploy_id,0),decode(nvl(a.wx_couponemploy_id,0),0,'N','Y'),a.address,a.wx_address_id
    INTO v_client_id,v_groupon_id, v_ordertype, v_order_id, v_userid,v_couponemploy_id,v_isUseCoupon,v_address,v_address_id
    FROM wx_order a
    WHERE a.id = p_id;
    --更新订单地址通过外键  如果订单已经填入地址，则不允许修改
    IF v_address is NULL THEN
	  update wx_order t set(t.province,t.city,t.regionid,t.address,t.name,t.phonenum) =
	         (select w.province,w.city,w.regionid,w.address,w.name,w.phonenum from wx_address w where w.id = v_address_id)
	          where t.id = p_id;
    END IF;
    IF v_ordertype = '2' AND v_groupon_id IS NULL THEN
        raise_application_error(-20014, '此单为特殊活动订单，请选择对应的销售活动');
    END IF;
		--判断券是否被其它订单引用
		if v_couponemploy_id>0 then
				select count(1)
				into v_coupon_count
				from wx_order o
				where nvl(o.wx_couponemploy_id,0)=v_couponemploy_id
				and o.id<>p_id
				and o.ad_client_id=v_client_id;
				if v_coupon_count>=1 then
					 raise_application_error(-20014, '优惠券已被其它订单引用，请重新选择');
				end if;
		end if;
		if v_ordertype='1' then
		   begin
					--判断优惠券是否已过期
					/*select case when to_number(to_char(g.starttime,'yyyymmdd'))<=v_currentDate and v_currentDate<= to_number(to_char(g.endtime,'yyyymmdd')) then 'N' else 'Y' end,to_number(nvl(g.value,'0'))
					into v_isOverdue,v_coupon_money
					from wx_coupon g join wx_couponemploy ce on ce.wx_coupon_id=g.id
					where ce.id=v_couponemploy_id;*/
					select to_number(nvl(g.value, '0')),'N',g.id
					into   v_coupon_money,v_isOverdue,v_coupon_id
					from   wx_coupon g, wx_couponemploy t
					where  g.id = t.wx_coupon_id
					and    sysdate between g.starttime and
								 decode(g.validay, null, g.endtime, t.creationdate + g.validay)
					and    t.id = v_couponemploy_id;
			exception when others then
			       v_coupon_id:=null;
						 v_couponemploy_id:=null;
						 v_isOverdue:='Y';
						 v_coupon_money:=0;
			end;
			/*if nvl(v_isOverdue,'N')='Y' then
				 raise_application_error(-20201,'优惠券已过期，不能使用！');
			end if;*/
			--如果优惠金额大于0时，更新订单总金额，同时把优惠券状态改为已使用
			--if nvl(v_coupon_money,0)>0 and nvl(v_isOverdue,'N')='N' then
					--更新总金额
					UPDATE wx_order s
					SET (s.tot_amt_actual, s.tot_amt_pricelist, s.tot_amt, s.tot_qty,s.wx_coupon_id,s.wx_couponemploy_id) =
							 (SELECT SUM(a.amt_priceactual), SUM(a.amt_pricelist),
											 greatest((SUM(a.amt_priceactual)+nvl(s.logistics_free,0)-nvl(v_coupon_money,0)),0), SUM(a.qty),v_coupon_id,v_couponemploy_id
								FROM wx_orderitem a
								WHERE a.wx_order_id = p_id)
					WHERE s.id = p_id;
					--修改优惠券状态
					--update wx_couponemploy cm set cm.state='Y' where cm.id=v_couponemploy_id;
			--end if;
    --刷新团购单明细数据
    elsiF v_groupon_id IS NOT NULL AND v_ordertype = '2' THEN
        INSERT INTO wx_orderitem
            (id, ad_client_id, ad_org_id, wx_order_id, wx_appendgoods_id, qty,
             size_name, color, pricelist, priceactual, amt_pricelist,
             amt_priceactual, discount, ownerid, modifierid, creationdate,
             modifieddate, isactive)
            SELECT get_sequences('wx_orderitem'), m.ad_client_id, m.ad_org_id,
                   v_order_id, m.wx_appendgoods_id, 0, NULL, NULL,
                   p.itemunitprice, 0, 0, 0, 0, v_userid, v_userid, SYSDATE,
                   SYSDATE, 'Y'
            FROM wx_groupon m, wx_appendgoods p
            WHERE m.id = v_groupon_id
            AND m.wx_appendgoods_id = p.id;
    elsif v_ordertype='3' then
		    UPDATE wx_order s
				SET (s.tot_amt_actual, s.tot_amt_pricelist, s.tot_amt, s.tot_qty,s.wx_coupon_id) =
						 (SELECT SUM(a.amt_priceactual), SUM(a.amt_pricelist),
										 SUM(a.amt_priceactual), SUM(a.qty),v_coupon_id
							FROM wx_orderitem a
							WHERE a.wx_order_id = p_id)
				WHERE s.id = p_id;
    END IF;
END;

/
create or replace FUNCTION WX_ORDER_$r_GETORDER(p_user_id IN NUMBER,

                                                p_param IN VARCHAR2)
 return varchar2 is
    -------------------------------------------------------------------------
    --add by hcy 20141016
    --查询代发货订单的数量，待处理维权，昨日的下单数量，昨日的成交金额
    -------------------------------------------------------------------------
    v_sale_count NUMBER(10);
    v_ispaying NUMBER(10); --待付款
    v_orderyesterday_count NUMBER(10);
    v_yesterday_totamt NUMBER(14, 2);
    jor         json := NEW json();
    v_client_id number(10);
BEGIN
    select t.ad_client_id into v_client_id from users t where t.id = p_user_id;
    --查询待发货订单个数，昨日下单数，昨日成交金额，待付款
    select count(*)
    into v_sale_count
    from WX_ORDER t
    where t.SALE_STATUS = 3 and t.ad_client_id = v_client_id;
    select count(*)
    into v_orderyesterday_count
    from WX_ORDER t
    where ROUND(TO_NUMBER(SYSDATE - t.CREATIONDATE)) = 1 and
          t.ad_client_id = v_client_id;
    select nvl(sum(t.TOT_AMT_ACTUAL), 0)
    into v_yesterday_totamt
    from WX_ORDER t
    where ROUND(TO_NUMBER(SYSDATE - t.CREATIONDATE)) = 1 and
          t.ad_client_id = v_client_id;
    select count(*)
    into v_ispaying
    from WX_ORDER t
    where t.SALE_STATUS = 2 and t.ad_client_id = v_client_id;
    jor.put('salecount', v_sale_count);
    jor.put('ispaying', v_ispaying);
    jor.put('yescount', v_orderyesterday_count);
    jor.put('yestotamt', v_yesterday_totamt);
    return jor.to_char(false);
END;

/
create or replace FUNCTION WX_ORDER_$r_GETORDERAMT(p_user_id IN NUMBER,

                                                   p_param IN VARCHAR2)
 return varchar2 is
    -------------------------------------------------------------------------
    --add by hcy 20141016
    --查询7天下单数，7天订单成交数，7天退单数，7天总金额，7天成交额，7天退款额
    -------------------------------------------------------------------------
    order_amt NUMBER(10);
    deal_amt NUMBER(10);
    backorder_amt NUMBER(10);
    TOT_AMT_PRICELIST number(14, 2);
    TOT_AMT_ACTUAL number(14, 2);
    TOT_AMT_BACK number(14, 2);
    systime varchar2(20);
    days    NUMBER(10);
    jor1 json;
    jor       json := NEW json();
    jor_list  json_list := json_list();
    jor_list1 json_list := json_list();
    jor_list2 json_list := json_list();
    jor_list3 json_list := json_list();
    jor_list4 json_list := json_list();
    v_client_id number(10);
BEGIN
    jor1 := json(p_param);
    days := jor1.get('days').get_number;
    select t.ad_client_id into v_client_id from users t where t.id = p_user_id;
    --查询系统时间
    select to_char(sysdate, 'yyyy-mm-dd') into systime from dual;
    --查询7天每天的下单数
    for i in 0 .. days - 1 loop
        select count(*)
        into order_amt
        from WX_ORDER t
        where TO_CHAR(CREATIONDATE, 'yyyy-mm-dd') =
              TO_CHAR(sysdate - (days - i), 'yyyy-mm-dd') and
              t.ad_client_id = v_client_id;
        jor_list.add_elem(order_amt);
    end loop;
    --查询7天每天的成交数
    for i in 0 .. days - 1 loop
        select count(*)
        into deal_amt
        from WX_ORDER t
        where t.SALE_STATUS = 5 and TO_CHAR(CREATIONDATE, 'yyyy-mm-dd') =
              TO_CHAR(sysdate - (days - i), 'yyyy-mm-dd') and
              t.ad_client_id = v_client_id;
        jor_list1.add_elem(deal_amt);
    end loop;
    --查询7天每天的退单数
    for i in 0 .. days - 1 loop
        select count(*)
        into backorder_amt
        from WX_ORDER t
        where t.SALE_STATUS = 4 and TO_CHAR(CREATIONDATE, 'yyyy-mm-dd') =
              TO_CHAR(sysdate - (days - i), 'yyyy-mm-dd') and
              t.ad_client_id = v_client_id;
        jor_list2.add_elem(backorder_amt);
    end loop;
    --查询7天每天的成交额
    for i in 0 .. days - 1 loop
        select nvl(sum(t.tot_amt_actual), 0)
        into TOT_AMT_ACTUAL
        from WX_ORDER t
        where TO_CHAR(CREATIONDATE, 'yyyy-mm-dd') =
              TO_CHAR(sysdate - (days - i), 'yyyy-mm-dd') and
              t.ad_client_id = v_client_id;
        jor_list3.add_elem(TOT_AMT_ACTUAL);
    end loop;
    --查询7天每天的退款额
    for i in 0 .. days - 1 loop
        select nvl(sum(t.tot_amt_actual), 0)
        into TOT_AMT_BACK
        from WX_ORDER t
        where t.SALE_STATUS = 7 and TO_CHAR(CREATIONDATE, 'yyyy-mm-dd') =
              TO_CHAR(sysdate - (days - i), 'yyyy-mm-dd') and
              t.ad_client_id = v_client_id;
        jor_list4.add_elem(TOT_AMT_BACK);
    end loop;
    --查询7天下单数，7天订单成交数，7天退单数，7天总金额，7天成交额，7天退款额
    select count(*)
    into order_amt
    from WX_ORDER t
    where TO_CHAR(CREATIONDATE, 'yyyy-mm-dd') >=
          TO_CHAR(sysdate - 7, 'yyyy-mm-dd') and
          TO_CHAR(CREATIONDATE, 'yyyy-mm-dd') < to_char(sysdate, 'yyyy-mm-dd') and
          t.ad_client_id = v_client_id;
    select count(*)
    into deal_amt
    from WX_ORDER t
    where t.SALE_STATUS = 5 and TO_CHAR(CREATIONDATE, 'yyyy-mm-dd') >=
          TO_CHAR(sysdate - 7, 'yyyy-mm-dd') and
          TO_CHAR(CREATIONDATE, 'yyyy-mm-dd') < to_char(sysdate, 'yyyy-mm-dd') and
          t.ad_client_id = v_client_id;
    select count(*)
    into backorder_amt
    from WX_ORDER t
    where t.SALE_STATUS = 4 and TO_CHAR(CREATIONDATE, 'yyyy-mm-dd') >=
          TO_CHAR(sysdate - 7, 'yyyy-mm-dd') and
          TO_CHAR(CREATIONDATE, 'yyyy-mm-dd') < to_char(sysdate, 'yyyy-mm-dd') and
          t.ad_client_id = v_client_id;
    select nvl(sum(t.tot_amt_pricelist), 0)
    into TOT_AMT_PRICELIST
    from Wx_Order t
    where TO_CHAR(CREATIONDATE, 'yyyy-mm-dd') >=
          TO_CHAR(sysdate - 7, 'yyyy-mm-dd') and
          TO_CHAR(CREATIONDATE, 'yyyy-mm-dd') < to_char(sysdate, 'yyyy-mm-dd') and
          t.ad_client_id = v_client_id;
    select nvl(sum(t.tot_amt_actual), 0)
    into TOT_AMT_ACTUAL
    from Wx_Order t
    where TO_CHAR(CREATIONDATE, 'yyyy-mm-dd') >=
          TO_CHAR(sysdate - 7, 'yyyy-mm-dd') and
          TO_CHAR(CREATIONDATE, 'yyyy-mm-dd') < to_char(sysdate, 'yyyy-mm-dd') and
          t.ad_client_id = v_client_id;
    select nvl(sum(t.tot_amt_actual), 0)
    into TOT_AMT_BACK
    from Wx_Order t
    where t.SALE_STATUS = 7 and TO_CHAR(CREATIONDATE, 'yyyy-mm-dd') >=
          TO_CHAR(sysdate - 7, 'yyyy-mm-dd') and
          TO_CHAR(CREATIONDATE, 'yyyy-mm-dd') < to_char(sysdate, 'yyyy-mm-dd') and
          t.ad_client_id = v_client_id;
    jor.put('days', days);
    jor.put('systime', systime);
    jor.put('order_amt', order_amt);
    jor.put('deal_amt', deal_amt);
    jor.put('TOT_AMT_PRICELIST', TOT_AMT_PRICELIST);
    jor.put('TOT_AMT_ACTUAL', TOT_AMT_ACTUAL);
    jor.put('TOT_AMT_BACK', TOT_AMT_BACK);
    jor.put('backorder_amt', backorder_amt);
    jor.put('order_amtlist', jor_list);
    jor.put('deal_amtlist', jor_list1);
    jor.put('backorder_amtlist', jor_list2);
    jor.put('TOT_AMT_ACTUALLIST', jor_list3);
    jor.put('TOT_AMT_BACKLIST', jor_list4);
    return jor.to_char(false);
END;

/
create or replace FUNCTION WX_ISSUEARTICLE_$r_GETSUM(p_user_id IN NUMBER,

                                                     p_param IN VARCHAR2)
 return varchar2 is
    -------------------------------------------------------------------------
    --add by hcy 20141027
    -------------------------------------------------------------------------
    menu_amt          NUMBER(10);
    hotbook_amt       NUMBER(10);
    book_amt          NUMBER(10);
    result_clob       clob;
    book_clob         clob;
    menuappsec        varchar2(100);
    menucname         varchar2(50);
    menupublictype    NUMBER(10);
    wx_articleamt     NUMBER(10);
    wx_articlegroyamt NUMBER(10);
    jor      json := NEW json();
    jor_list json_list := json_list();
    v_client_id number(10);
BEGIN
    select t.ad_client_id into v_client_id from users t where t.id = p_user_id;
    --查询前十文章的浏览数量
    select wm_concat('''' || articletitle || ''':' || browsenum)
    into book_clob
    from (select *
           from WX_ISSUEARTICLE t
           where t.ad_client_id = v_client_id and t.browsenum is not null
           order by t.browsenum desc)
    where rownum < 11;
    --查询访问官网次数
    select nvl(sum(s.visitnumber), 0)
    into menu_amt
    from wx_setinfo s
    where s.ad_client_id = v_client_id;
    --查询热门文章浏览次数
    select nvl(max(browsenum), 0)
    into hotbook_amt
    from WX_ISSUEARTICLE t
    where t.ad_client_id = v_client_id;
    jor_list.add_elem(hotbook_amt);
    --查询文章浏览次数
    select nvl(sum(browsenum), 0)
    into book_amt
    from WX_ISSUEARTICLE t
    where t.ad_client_id = v_client_id;
    --查询文章总数
    select count(*)
    into wx_articleamt
    from WX_ISSUEARTICLE t
    where t.ad_client_id = v_client_id;
    --查询文章分类总数
    select count(*)
    into wx_articlegroyamt
    from WX_ARTICLECATEGORY t
    where t.ad_client_id = v_client_id;
    select t.publictype
    into menupublictype
    from WX_INTERFACESET t
    where t.ad_client_id = v_client_id;
    select t.appsecret
    into menuappsec
    from WX_INTERFACESET t
    where t.ad_client_id = v_client_id;
    select t.wxnum
    into menucname
    from WEB_CLIENT t
    where t.ad_client_id = v_client_id;
    --饼图
    select wm_concat('''' || a.categoryname || ''':' ||
                      nvl(sum(t.browsenum), 0))
    into result_clob
    from WX_ISSUEARTICLE t, WX_ARTICLECATEGORY a
    where t.wx_articlecategory_id = a.id and t.ad_client_id = v_client_id
    group by a.categoryname;
    jor.put('book_amtlist', jor_list);
    jor.put('book_amt', book_amt);
    jor.put('menu_amt', menu_amt);
    jor.put('menucname', menucname);
    jor.put('articleamt', wx_articleamt);
    jor.put('articlegroyamt', wx_articlegroyamt);
    jor.put('menupublictype', menupublictype);
    jor.put('menuappsec', menuappsec);
    jor.put('result_clob', result_clob);
    jor.put('book_clob', book_clob);
    return jor.to_char(false);
END;

/
create or replace function wx_menu_create(ad_clientid in number)

    return varchar2 as
    /*
    jack
    wx_meunset
    */
    -- json
    v_publictype varchar2(20);
    v_domain     varchar2(100);
    v_sr1        varchar2(4000);
    v_sr2        varchar2(4000);
    v_appid      varchar2(100);
    v_url        varchar2(4000);
    v_fid        number(10);
    v_url1       varchar2(4000);
    v_replace    varchar2(4000);
    v_menuclob   clob;
    jo           json;
    jos1         json;
    jolist       json_list;
    jolist_tmp   json_list;
begin
    SELECT s.publictype,s.appid
    INTO v_publictype, v_appid
    FROM wx_interfaceset s
    WHERE s.ad_client_id = ad_clientid;
    SELECT 'http://'||wc.domain
    INTO v_domain
    FROM web_client wc
    WHERE wc.ad_client_id = ad_clientid;
    IF v_publictype = '4' THEN
        v_sr1 := 'https://open.weixin.qq.com/connect/oauth2/authorize?appid=' ||
                 v_appid || '&redirect_uri=';
        v_sr2 := '&response_type=code&scope=snsapi_base&state=1#wechat_redirect';
    ELSE
        v_sr1 := '';
        v_sr2 := '';
    END IF;
    select t.menucontent
    into v_menuclob
    from wx_menuset t
    where t.ad_client_id = ad_clientid;
    jo := json(v_menuclob);
    if (jo.exist('button')) then
        if (jo.get('button').is_array) then
            jolist := json_list(jo.get('button'));
            FOR v IN 1 .. jolist.count LOOP
                jos1 := json(jolist.get_elem(v));
                if (jos1.exist('sub_button') = false) then
                    if (jos1.get('type').get_string = 'view') then
                        v_fid     := jos1.get('fromid').get_number;
                        v_replace := jos1.get('objid').get_string;
                        SELECT t.purl
                        INTO v_url
                        FROM wx_v_jumpurlpath t
                        WHERE t.id = v_fid+ad_clientid and t.AD_CLIENT_ID=ad_clientid;
                        IF v_url IS NULL THEN
                            v_url1 := v_replace;
                        ELSE
												    --v_url1 :=replace(nvl(v_domain||v_url,''), '@ID@', nvl(v_replace, ' '));
                            v_url1 :=v_sr1||case when v_publictype='4'
                                                then replace(apex_util.url_encode(replace(nvl(v_domain||v_url,''), '@ID@', nvl(v_replace, ' '))),'%2E','.')
                                                else replace(nvl(v_domain||v_url,''), '@ID@', nvl(v_replace, ' '))
                                           end
                                ||v_sr2;
                        END IF;
                        json_ext.remove(jo, 'button[' || v || '].key');
                        json_ext.put(jo, 'button[' || v || '].url', v_url1);
                    end if;
                    json_ext.remove(jo, 'button[' || v || '].fromid');
                    json_ext.remove(jo, 'button[' || v || '].objid');
                    json_ext.remove(jo, 'button[' || v || '].menuType');
                elsif (jos1.exist('sub_button')) then
                    if (jos1.get('sub_button').is_array) then
                        jolist_tmp := json_list(jos1.get('sub_button'));
                        IF jolist_tmp.count<=0 THEN
                           json_ext.remove(jo, 'button[' || v || '].sub_button');
                           if (jos1.get('type').get_string = 'view') then
                              v_fid     := jos1.get('fromid').get_number;
                              v_replace := jos1.get('objid').get_string;
                              SELECT t.purl
                              INTO v_url
                              FROM wx_v_jumpurlpath t
                              WHERE t.id = v_fid;
                              IF v_url IS NULL THEN
                                  v_url1 := v_replace;
                              ELSE
															    --v_url1 :=replace(nvl(v_domain||v_url,''), '@ID@', nvl(v_replace, ' '));
                                  v_url1 :=v_sr1||case when v_publictype='4'
                                                then replace(apex_util.url_encode(replace(nvl(v_domain||v_url,''), '@ID@', nvl(v_replace, ' '))),'%2E','.')
                                                else replace(nvl(v_domain||v_url,''), '@ID@', nvl(v_replace, ' '))
                                           end
                                ||v_sr2;
                              END IF;
                              json_ext.remove(jo, 'button[' || v || '].key');
                              json_ext.put(jo, 'button[' || v || '].url', v_url1);
                          end if;
                          json_ext.remove(jo, 'button[' || v || '].fromid');
                          json_ext.remove(jo, 'button[' || v || '].objid');
                          json_ext.remove(jo, 'button[' || v || '].menuType');
                        ELSE
                          FOR j IN 1 .. jolist_tmp.count LOOP
                              jos1 := json(jolist_tmp.get_elem(j));
                              if (jos1.get('type').get_string = 'view') then
                                  v_fid     := jos1.get('fromid').get_number;
                                  v_replace := jos1.get('objid').get_string;
                                  SELECT t.purl
                                  INTO v_url
                                  FROM wx_v_jumpurlpath t
                                  WHERE t.id = v_fid+ad_clientid and t.AD_CLIENT_ID=ad_clientid;
                                  IF v_url IS NULL THEN
                                      v_url1 := v_replace;
                                  ELSE
																	    --v_url1 :=replace(nvl(v_domain||v_url,''), '@ID@', nvl(v_replace, ' '));
                                      v_url1 := v_sr1||case when v_publictype='4'
                                                then replace(apex_util.url_encode(replace(nvl(v_domain||v_url,''), '@ID@', nvl(v_replace, ' '))),'%2E','.')
                                                else replace(nvl(v_domain||v_url,''), '@ID@', nvl(v_replace, ' '))
                                           end
                                           ||v_sr2;
                                  END IF;
                                  -- remove key
                                  json_ext.remove(jo,
                                                  'button[' || v ||
                                                  '].sub_button[' || j || '].key');
                                  json_ext.remove(jo,
                                                  'button[' || v ||
                                                  '].sub_button[' || j ||
                                                  '].fromid');
                                  json_ext.remove(jo,
                                                  'button[' || v ||
                                                  '].sub_button[' || j ||
                                                  '].objid');
                                  json_ext.put(jo,
                                               'button[' || v || '].sub_button[' || j ||
                                               '].url',
                                               v_url1);
                              end if;
                          json_ext.remove(jo,
                                                  'button[' || v ||
                                                  '].sub_button[' || j ||
                                                  '].menuType');
                          end loop;
                       END IF;
                    end if;
                end if;
            end loop;
            --  jo.print;
        end if;
    end if;
    return jo.to_char(false);
end;

/
create or replace procedure wx_order_accept(p_user_id in number,

                                            p_query   in varchar2,
                                            r_code    out number,
                                            r_message out varchar2) as
    type t_queryobj is record(
        tableid number(10),
        query   varchar2(32676),
        id      varchar2(10));
    v_queryobj t_queryobj;
    type t_selection is table of number(10) index by binary_integer;
    v_selection t_selection;
    st_xml      varchar2(32676);
    v_xml       xmltype;
		p_integral_ratio number(10);
		p_isOffline      char(1):='N';
		p_vipId          number(10);
		p_orderState     number(10);
		p_openid         varchar(100);
    p_id number(10);
		p_integral number(10);
		p_paycode  varchar2(100);
		v_couponemploy_id  number(10);
begin
    -- 从p_query解析参数
    st_xml := '<data>' || p_query || '</data>';
    --raise_application_error(-20014, st_xml);
    v_xml := xmltype(st_xml);
    select extractvalue(value(t), '/data/table'),
           extractvalue(value(t), '/data/query'),
           extractvalue(value(t), '/data/id')
    into   v_queryobj
    from   table(xmlsequence(extract(v_xml, '/data'))) t;
    select extractvalue(value(t), '/selection') bulk collect
    into   v_selection
    from   table(xmlsequence(extract(v_xml, '/data/selection'))) t;
    p_id := v_queryobj.id;
		select o.wx_vip_id,o.sale_status,o.wx_couponemploy_id
		into p_vipId,p_orderState,v_couponemploy_id
		from wx_order o
		where o.id=p_id;
		--判断是否已收货过
		if p_orderState=5 then
		   raise_application_error(-20201,'此单已收货，不能重复收货！');
		end if;
		--更新单据状态
    update wx_order t set t.sale_status = '5' where t.id = p_id;
    --查询下单会员所属VIP类型的积分比例
		begin
				select to_number(nvl(vb.integralconvert,0))
				into p_integral_ratio
				from wx_vipbaseset vb
				where vb.id=(select v.viptype from wx_vip v where v.id=p_vipId);
		exception when others then
		    p_integral_ratio:=0;
		end;
		--获取订单支付方式，如果为积分支付，则不需要产生积分
		begin
			select p.pcode
			into p_paycode
			from wx_pay p
			where p.id=(select o.payment from wx_order o where o.id=p_id);
		exception when others then
		  p_paycode:='';
		end;
		--如果公司未接通线下，则产生积分流水与消弱记录
		select ifs.iserp
		into p_isOffline
		from wx_interfaceset ifs
		where ifs.ad_client_id=(select o.ad_client_id from wx_order o where o.id=p_id);
		/*if nvl(trim(v_couponemploy_id),null) is not null then
				--修改优惠券状态
				update wx_couponemploy cm set cm.state='Y' where cm.id=v_couponemploy_id;
		end if;*/
		if p_isOffline='N' then --and nvl(p_paycode,'')<>'integral'
			 --判断积分是否大于0
			 --计算积分
			 select decode(o.ordertype,'3',-o.amt_integral,to_number(decode(p_integral_ratio,0,0,o.tot_amt/p_integral_ratio)))
			 into p_integral
			 from wx_order o where o.id=p_id;
			 if p_integral>0 then
			     --插入VIP积分流水
					 insert into wx_integral
										(id, ad_client_id, ad_org_id, wx_vip_id, wx_order_id, docno, saledate, c_store_id, amt, integral,
										 integraltype, ownerid, modifierid, creationdate, modifieddate, isactive, wechatno, remark)
										select get_sequences('wx_integral'), o.ad_client_id, o.ad_org_id, p_vipId, null, get_sequenceno('INGR', o.ad_client_id),
													 to_number(to_char(sysdate, 'YYYYMMDD')), null, 0,p_integral, 1, o.ownerid,
													 o.modifierid, sysdate, sysdate, 'Y', v.wechatno, '由订单'||o.docno||'产生'
										from   wx_order o join wx_vip v on v.id=o.wx_vip_id
										where  o.id=p_id;
					 --修改会员总积分
					 update wx_vip v set v.integral=nvl(v.integral,0)+p_integral
					 where v.id=p_vipId;
			 end if;
			 --更新会员消费信息
			 update wx_vip v set (v.orderqty,v.productqty,v.totalprice)=
			 (select nvl(v.orderqty,0)+1,nvl(v.productqty,0)+nvl(o.tot_qty,0),nvl(v.totalprice,0)+o.tot_amt from wx_order o where o.id=p_id);
		end if;
		--插入VIP消费记录
	  insert into wx_deal
						(id, ad_client_id, ad_org_id, wx_vip_id, wx_order_id, dealtype, dealamt, lastamt, useintegral, description,
						 ownerid, modifierid, creationdate, modifieddate, isactive, wechatno, docno, saledate)
						select get_sequences('wx_deal'), v.ad_client_id, v.ad_org_id, v.id,o.id,'线上消费',o.tot_amt,v.lastamt,
										nvl(o.amt_integral,0),'由订单'||o.docno||'产生',
									 v.ownerid, v.modifierid, sysdate, sysdate, 'Y', v.wechatno, null,
									 to_number(to_char(sysdate,'yyyymmdd'))
						from   wx_order o join wx_vip v on v.id=o.wx_vip_id
						where  o.id=p_id;
end;

/
create or replace function wx_productcategory_$r_savejson(p_user_id IN NUMBER,f_data in varchar)

    return varchar2 is
    f_data_ja      json_list;
		f_result_jo    json:=new json();
    f_temp_data_jo json;
		f_cid          number(10);
		f_pcid         number(10);
		f_operate      varchar2(100);
		f_ids          varchar2(1000);
		f_pcname       varchar2(1000);
		f_pcanmes      varchar2(4000);
begin
    begin
        f_data_ja := json_list(f_data);
    exception when others then
		    f_result_jo.put('code',-1);
		    f_result_jo.put('data',f_ids);
		    return f_result_jo.to_char;
        --f_data_ja := new json_list();
    end;
    for i in 1 .. f_data_ja.count loop
        f_temp_data_jo := json(f_data_ja.get_elem(i));
        if f_temp_data_jo.exist('id')=false then
				   continue;
				end if;
				f_pcid:=f_temp_data_jo.get('id').get_number;
				if f_temp_data_jo.exist('operate')=false then
				   continue;
				end if;
				f_operate:=f_temp_data_jo.get('operate').get_string;
				if f_operate is null then
				   continue;
				end if;
				if f_temp_data_jo.exist('categoryid')=false then
				   continue;
				else
				   f_cid:=f_temp_data_jo.get('categoryid').get_number;
					 if trim(f_cid) is null then
					    continue;
					 end if;
				end if;
				if lower(f_operate)='add' then
				   if f_pcid=-1 then
					    f_pcid:=get_sequences('WX_PRODUCTCATEGORY');
							INSERT INTO wx_productcategory
									(id, ad_client_id, ad_org_id, creationdate,
									 modifieddate, isactive, wx_itemcategoryset_id,ownerid,modifierid)
							SELECT f_pcid, u.ad_client_id, u.ad_org_id, SYSDATE, SYSDATE, 'Y',trim(f_cid),p_user_id,p_user_id
							FROM users u
							WHERE u.id=p_user_id;
					 end if;
			  elsif lower(f_operate)='delete' then
				      delete from wx_productcategory pc where pc.id=f_pcid;
							continue;
				end if;
				if f_ids is not null then
				   f_ids:=f_ids||',';
				end if;
				f_ids:=f_ids||f_pcid;
    end loop;
		f_result_jo.put('code',0);
		f_result_jo.put('data',f_ids);
		return f_result_jo.to_char;
end;

/
create or replace PROCEDURE wx_pay_acm(p_id IN NUMBER) AS

    -------------------------------------------------------------------------
    --add by zwm 20140418
    --判断支付方式是否已被引用
    -------------------------------------------------------------------------
    v_count NUMBER(10);
		v_isdefault varchar2(10);
		v_adclient_id number(10);
BEGIN
    --获取当前记录支付方式
		select nvl(p.isdefault,'N'),p.ad_client_id
		into v_isdefault,v_adclient_id
		from wx_pay p
		where p.id=p_id;
		--如果当前记录不是默认支付方式
		if v_isdefault='N' then
				--判断是否有默认支付方式
				begin
						select count(1)
						into v_count
						from wx_pay p
						where p.ad_client_id=v_adclient_id
						and p.isdefault='Y';
				exception when others then
						v_count:=0;
				end;
				--没有时修改一条记录为默认支付方式
				if v_count=0 then
					 update wx_pay p set p.isdefault='Y' where rownum=1;
				end if;
		else
		    --修改其它默认支付方式为非默认支付方式
				update wx_pay p set p.isdefault='N' where p.ad_client_id=v_adclient_id and p.id<>p_id;
		end if;
END;

/
create or replace function getsendsmscount(f_company_id in number)

    return number is
    f_sendsmscount number(10);
begin
    select count(1)
    into   f_sendsmscount
    from   u_message e
		where    e.ad_client_id=f_company_id
    and    e.state = 2;
    return f_sendsmscount;
end;
