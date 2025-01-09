class zcl_rap_eml_8888 definition
  public final
  create public.

  public section.
    interfaces if_oo_adt_classrun.
endclass.


class zcl_rap_eml_8888 implementation.
  method if_oo_adt_classrun~main.
    " STEP 1 - Se lee campo TravelUUID
    " read entities of zi_rap_travel_8888
    "      entity Travel
    "      from value #( ( TravelUUID = 'F67F61D58FD04C311900AD62CC64C96A' ) )
    "      result data(travels).
    "
    "      out->write( travels ).

    " STEP 2 - Se leen dos campos
    " read entities of zi_rap_travel_8888
    "      entity Travel
    "      fields ( AgencyID CustomerID )
    "      with value #( ( TravelUUID = 'F67F61D58FD04C311900AD62CC64C96A' ) )
    "      result data(travels).
    "
    " out->write( travels ).

    " STEP 3 - Se leen todos los campos
    " read entities of zi_rap_travel_8888
    "      entity Travel
    "      all fields with value #( ( TravelUUID = 'F67F61D58FD04C311900AD62CC64C96A' ) )
    "      result data(travels).
    "
    " out->write( travels ).

    " STEP 4 - Lectura por asociacion
    " read entities of zi_rap_travel_8888
    "      entity Travel by \_Booking
    "      all fields with value #( ( TravelUUID = 'F67F61D58FD04C311900AD62CC64C96A' ) )
    "      result data(bookings).
    "
    " out->write( bookings ).

    " STEP 5 - Lectura fallida
    " read entities of zi_rap_travel_8888
    "      entity Travel
    "      all fields with value #( ( TravelUUID = '11111111111111111111111111111111' ) )
    "      result data(travels)
    "      failed data(failed)
    "      reported data(reported).
    "
    " out->write( travels ).
    " out->write( failed ).
    " out->write( reported ).

    " STEP 6 - Se modifican campos
    " modify entities of zi_rap_travel_8888
    "        entity travel
    "        update
    "        set fields with value
    "         #( ( TravelUUID  = 'A7AB8FD58FD04C311900AD62CC64C96A'
    "              description = 'Me gusta RAP@OPENSAP' ) )
    "
    "        failed data(failed)
    "        reported data(reported).
    "
    " out->write( 'Update done' ).
    "
    " STEP 6b - persistir modificaciones
    " commit entities response of zi_rap_travel_8888
    "        failed data(failed_commit)
    "        reported data(reported_commit).

    " STEP 7 - Creación
    " modify entities of zi_rap_travel_8888
    "        entity travel
    "        create
    "        set fields with value
    "         #( ( %cid  = 'MyContenID_1'
    "              agencyID = '70012'
    "              CustomerID = '14'
    "              BeginDate = cl_abap_context_info=>get_system_date( )
    "              EndDate = cl_abap_context_info=>get_system_date( ) + 10
    "              description = 'Me gusta RAP@OPENSAP' ) )
    "
    "        MAPPED DATA(mapped)
    "        failed data(failed)
    "        reported data(reported).
    "
    " out->write( mapped-travel ).
    "
    " STEP 6b - persistir modificaciones
    " commit entities response of zi_rap_travel_8888
    "        failed data(failed_commit)
    "        reported data(reported_commit).
    " out->write( 'Create done' ).

    " STEP 8 - DELETE
    modify entities of zi_rap_travel_8888
           entity travel
           delete from
           value #( ( TravelUUID = 'CE3B9E4417721EDFB3D17862088A0E3C' ) )
*           Cust 000014
           mapped data(mapped)
           failed data(failed)
           reported data(reported).

    out->write( mapped-travel ).

    " STEP 6b - persistir modificaciones
    commit entities response of zi_rap_travel_8888
           failed data(failed_commit)
           reported data(reported_commit).

    out->write( 'Delete done' ).

  endmethod.
endclass.