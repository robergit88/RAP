*&---------------------------------------------------------------------*
*& ID_PROGRAMA: zcl_generate_demo_data_8888                            *
*&                                                                     *
*& TIPO DE PROGRAMA: REPORT                                            *
*&                                                                     *
*& DESCRIPCION: Clase para llenar tablas de persistencia               *
*&                                                                     *
*& AUTOR: CB9980008837 - Roberto Puma                                  *
*&                                                                     *
*& FECHA DE CREACIÓN: 09.01.2025                                       *
*&                                                                     *
*&---------------------------------------------------------------------*
*&                                                                     *
*& HISTORIAL DE CAMBIOS                                                *
*&                                                                     *
*&  FECHA      AUTOR        DESC.                                      *
*&  ------     ----------   -------------                              *
*& DD.MM.AAAA  XXXXXXX      001                                        *
*&                                                                     *
*&---------------------------------------------------------------------*
class zcl_generate_demo_data_8888 definition
  public final
  create public.

  public section.
    interfaces if_oo_adt_classrun.
endclass.


class zcl_generate_demo_data_8888 implementation.
  method if_oo_adt_classrun~main.
    " delete existing entries in bb.dd
    delete from zrap_atrav_8888.
    delete from zrap_abook_8888.

    " insert travel demo data
    insert zrap_atrav_8888 from (
     select from /dmo/travel
       fields uuid( )            as travel_uuid,
              travel_id          as travel_id,
              customer_id        as customer_id,
              agency_id          as agency_id,
              begin_date         as begin_date,
              end_date           as end_date,
              booking_fee        as booking_fee,
              total_price        as total_price,
              currency_code      as currency_code,
              description        as description,
              case status
               when 'B' then 'A' " ACCEPTED
               when 'X' then 'X' " CANCELED
               else 'O'          " OPEN
               end               as overall_status,
              createdby          as created_by,
              createdat          as created_at,
              lastchangedby      as last_changed_by,
              lastchangedat      as last_changed_at,
              lastchangedat      as local_last_changed_at
       order by travel_id
       up to 200 rows ).

    commit work.

    " insert booking demo data
    insert zrap_abook_8888 from (
        select
          from /dmo/booking as booking
                 join
                   zrap_atrav_8888 as z on booking~travel_id = z~travel_id
          fields uuid( )               as booking_uuid,
                 z~travel_uuid         as travel_uuid,
                 booking~booking_id    as booking_id,
                 booking~booking_date  as booking_date,
                 booking~customer_id   as customer_id,
                 booking~carrier_id    as carrier_id,
                 booking~connection_id as connection_id,
                 booking~flight_date   as flight_date,
                 booking~flight_price  as flight_price,
                 booking~currency_code as currency_code,
                 z~created_by          as created_by,
                 z~last_changed_by     as last_changed_by,
                 z~last_changed_at     as local_last_changed_by ).
    commit work.

    out->write( 'Travel and booking demo data inserted.' ).
  endmethod.
endclass.
