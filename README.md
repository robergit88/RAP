# Building Apps with the ABAP RESTful Application Programming Model 

## The big picture

![building_02](./img/building_02.png)

## Development flow

![building_03](./img/building_03.png)

## Construcción

![building_01](./img/building_01.png)

## ENTITY MANIPULATION LANGUAGE (EML)

[....detalle](./docs/EML.md)

## MANAGED APP

> framework handles CRUD operations automatically and is primarily used for greenfield developments where you build new apps from scratch using CDS and BDEF

[...detalle](./docs/MANAGED_APP.md)

## UNMANAGED APP

> Manually implement CRUD operations and is primarily used for brownfield developments where existing legacy code like BAPI

[....detalle](./docs/UNMANAGED_APP.md)

## STANDARD OBJECT /DMO/

### Paquetes:

- **`/DMO/FLIGHT_READONLY`**
represents a read-only list reporting app

- **`/DMO/FLIGHT_MANAGED`**
represents the transactional app with implementation type managed

- **`/DMO/FLIGHT_UNMANAGED`**
represents the transactional app with implementation type unmanaged 

- **`/DMO/FLIGHT_DRAFT`**
epresents the transactional app with draft

- **`/DMO/FLIGHT_HIERARCHY`** 
contains the development objects showcasing hierarchies in a read-only and an editable treeview scenario

- **`/DMO/FLIGHT_LEGACY`**
contains objects that are used for the unmanaged scenario to implement a brownfield scenario, for which the business logic is already implemented in legacy objects

## Vocabulario

[vocabulario](./docs/vocabulario.md)

## List of Useful SAP Fiori TCodes

[....detalle](./docs/transacciones.MD)
