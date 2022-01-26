# Logical Data Model

![logical data model view](../rendered/apps/data.logical.svg)

```plantuml
@startuml
scale 0.65

' avoid problems with angled crows feet
skinparam linetype ortho

class TKTK_Example {
  * id : integer <<generated>>
}
@enduml
```

### Notes

* See the help docs for [Entity Relationship Diagram](https://plantuml.com/ie-diagram) and [Class Diagram](https://plantuml.com/class-diagram) for syntax help.
* We're using the `*` visibility modifier to denote fields that cannot be `null`.
