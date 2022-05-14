type t

external unsafeToJsonSchema: 'a => t = "%identity"

module Raw = {
  type t

  external make: 'a => t = "%identity"

  @module
  external merge: (t, t) => t = "deepmerge"

  let description = value => make({"description": value})

  let default = value => make({"default": value})

  let schemaDialect = make({"$schema": "http://json-schema.org/draft-07/schema#"})

  let empty = make(Js.Dict.empty())

  let string = make({"type": "string"})
  let integer = make({"type": "integer"})
  let number = make({"type": "number"})
  let boolean = make({"type": "boolean"})
  let null = (innerSchema: t) => {
    make({
      "anyOf": [
        innerSchema,
        make({
          "type": "null",
        }),
      ],
    })
  }

  let array = (innerSchema: t) => {
    make({
      "items": innerSchema,
      "type": "array",
    })
  }

  let dict = (innerSchema: t) => {
    make({
      "type": "object",
      "additionalProperties": innerSchema,
    })
  }

  let record = (
    ~properties: Js.Dict.t<t>,
    ~additionalProperties: bool,
    ~required: array<string>,
  ) => {
    let schema = make({
      "type": "object",
      "properties": properties,
      "additionalProperties": additionalProperties,
    })
    switch required {
    | [] => schema
    | required => merge(schema, make({"required": required}))
    }
  }

  let deprecated: t = make({"deprecated": true})

  module Metadata = S.MakeMetadata({
    type content = t
    let namespace = "rescript-json-schema:raw"
  })
}

type node = {rawSchema: Raw.t, isRequired: bool}

let rec makeNode:
  type value. S.t<value> => result<node, JsonSchema_Error.t> =
  struct => {
    let maybeMetadataRawSchema = struct->Raw.Metadata.extract

    switch struct->S.classify {
    | S.String => Ok({rawSchema: Raw.string, isRequired: true})
    | S.Int => Ok({rawSchema: Raw.integer, isRequired: true})
    | S.Bool => Ok({rawSchema: Raw.boolean, isRequired: true})
    | S.Float => Ok({rawSchema: Raw.number, isRequired: true})
    | S.Array(innerStruct) =>
      makeNode(innerStruct)->Belt.Result.flatMap(innerNode => {
        if innerNode.isRequired {
          Ok({rawSchema: Raw.array(innerNode.rawSchema), isRequired: true})
        } else {
          Error(JsonSchema_Error.UnsupportedOptionalDictItem.make())
        }
      })
    | S.Option(innerStruct) =>
      makeNode(innerStruct)->Belt.Result.flatMap(innerNode => {
        if innerNode.isRequired {
          Ok({rawSchema: innerNode.rawSchema, isRequired: false})
        } else {
          Error(JsonSchema_Error.UnsupportedNestedOptional.make())
        }
      })
    | S.Record(fields) =>
      fields
      ->RescriptStruct_ResultX.Array.mapi((field, _) => {
        let (fieldName, fieldStruct) = field
        makeNode(fieldStruct)->RescriptStruct_ResultX.mapError(
          JsonSchema_Error.prependField(_, fieldName),
        )
      })
      ->Belt.Result.map(fieldNodes => {
        let rawSchema = {
          let properties = Js.Dict.empty()
          let required = []
          fieldNodes->Js.Array2.forEachi((fieldNode, idx) => {
            let field = fields->Js.Array2.unsafe_get(idx)
            let (fieldName, _) = field
            if fieldNode.isRequired {
              required->Js.Array2.push(fieldName)->ignore
            }
            properties->Js.Dict.set(fieldName, fieldNode.rawSchema)
          })
          Raw.record(~additionalProperties=false, ~properties, ~required)
        }
        {
          rawSchema: rawSchema,
          isRequired: true,
        }
      })
    | S.Unknown => Ok({rawSchema: Raw.empty, isRequired: true})
    | S.Null(innerStruct) =>
      makeNode(innerStruct)->Belt.Result.flatMap(innerNode => {
        if innerNode.isRequired {
          Ok({rawSchema: Raw.null(innerNode.rawSchema), isRequired: true})
        } else {
          Error(JsonSchema_Error.UnsupportedOptionalNullItem.make())
        }
      })
    | S.Dict(innerStruct) =>
      makeNode(innerStruct)->Belt.Result.flatMap(innerNode => {
        if innerNode.isRequired {
          Ok({rawSchema: Raw.dict(innerNode.rawSchema), isRequired: true})
        } else {
          Error(JsonSchema_Error.UnsupportedOptionalDictItem.make())
        }
      })
    | S.Deprecated({struct: innerStruct, maybeMessage}) =>
      makeNode(innerStruct)->Belt.Result.flatMap(innerNode => {
        let rawSchema = {
          let rawSchema' = Raw.merge(innerNode.rawSchema, Raw.deprecated)
          switch maybeMessage {
          | Some(message) => Raw.merge(rawSchema', Raw.description(message))
          | None => rawSchema'
          }
        }
        Ok({rawSchema: rawSchema, isRequired: false})
      })
    | S.Default({struct: innerStruct, value}) =>
      switch Some(value)->S.destructWith(innerStruct) {
      | Error(destructingErrorMessage) =>
        Error(JsonSchema_Error.DefaultDestructingFailed.make(~destructingErrorMessage))
      | Ok(destructedValue) =>
        makeNode(innerStruct)->Belt.Result.map(innerNode => {
          {
            rawSchema: Raw.merge(innerNode.rawSchema, Raw.default(destructedValue)),
            isRequired: false,
          }
        })
      }
    }->Belt.Result.map(node => {
      switch maybeMetadataRawSchema {
      | Some(metadataRawSchema) => {
          rawSchema: Raw.merge(node.rawSchema, metadataRawSchema),
          isRequired: node.isRequired,
        }
      | None => node
      }
    })
  }

let make = struct => {
  makeNode(struct)
  ->Belt.Result.flatMap(node => {
    if node.isRequired {
      Ok(Raw.merge(node.rawSchema, Raw.schemaDialect)->unsafeToJsonSchema)
    } else {
      Error(JsonSchema_Error.UnsupportedRootOptional.make())
    }
  })
  ->RescriptStruct_ResultX.mapError(JsonSchema_Error.toString)
}

let raw = (struct, providedRawSchema) => {
  let rawSchema = switch struct->Raw.Metadata.extract {
  | Some(existingRawSchema) => Raw.merge(existingRawSchema, providedRawSchema)
  | None => providedRawSchema
  }
  struct->Raw.Metadata.mixin(rawSchema)
}

let description = (struct, value) => {
  struct->raw(Raw.description(value))
}
