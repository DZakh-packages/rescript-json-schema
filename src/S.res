module FJS = {
  type t<'v>
  type json<'v>
  @module("fluent-json-schema")
  external object: unit => t<option<'v>> = "object"
  @module("fluent-json-schema")
  external string: unit => t<option<string>> = "string"
  @module("fluent-json-schema")
  external integer: unit => t<option<int>> = "integer"
  @module("fluent-json-schema")
  external boolean: unit => t<option<bool>> = "boolean"
  @module("fluent-json-schema")
  external number: unit => t<option<float>> = "number"
  @module("fluent-json-schema")
  external array: unit => t<option<array<'item>>> = "array"

  @send external prop: (t<'v>, string, t<'p>) => t<'v> = "prop"
  @send external required: (t<option<'v>>, unit) => t<'v> = "required"
  @send external items: (t<option<array<'item>>>, t<'item>) => t<option<array<'item>>> = "items"
  @send external valueOf: t<'v> => json<'v> = "valueOf"
}

type rec struct<'value> = {kind: kind<'value>, decoder: option<Js.Json.t => 'value>}
and kind<_> =
  | String: kind<string>
  | Int: kind<int>
  | Float: kind<float>
  | Bool: kind<bool>
  | Option(struct<'value>): kind<option<'value>>
  | Array(struct<'value>): kind<array<'value>>
  | Record1(field<'v1>): kind<'value>
  | Record2((field<'v1>, field<'v2>)): kind<'value>
  | Record3((field<'v1>, field<'v2>, field<'v3>)): kind<'value>

and field<'value> = (string, struct<'value>)

let make = (~kind, ~decoder=?, ()): struct<'value> => {
  {kind: kind, decoder: decoder}
}

external unsafeDecoder: Js.Json.t => 'value = "%identity"
let _decode:
  type src. (struct<src>, Js.Json.t) => src =
  (struct, unknown) => {
    switch struct.decoder {
    | Some(decoder) => unknown->decoder
    | None => unknown->unsafeDecoder
    }
  }

let decode = (struct, unknown) => {
  _decode(struct, unknown)
}
let decodeWith = (unknown, struct) => {
  _decode(struct, unknown)
}

module RecordHelper = {
  type construct<'value, 'ctx> = 'ctx => 'value
  type t<'value, 'ctx, 'fields> = {
    fields: 'fields,
    construct: construct<'value, 'ctx>,
  }

  let make = (~fields, ~construct) => {
    {
      fields: fields,
      construct: construct,
    }
  }

  let _decoder = %raw(`
function(fields, construct, decode) {
  var isSingleField = typeof fields[0] === "string";
  if (isSingleField) {
    return function(unknown) {
      var fieldName = fields[0],
        fieldStruct = fields[1];
      return construct(decode(fieldStruct, unknown[fieldName]));
    }
  }
  return function(unknown) {
    var ctx = [];
    fields.forEach(function (field) {
      var fieldName = field[0],
        fieldStruct = field[1];
      ctx.push(decode(fieldStruct, unknown[fieldName]));
    })
    return construct(ctx);
  }
}
`)

  let decoder = (self: t<'value, 'ctx, 'fields>, unknown: Js.Json.t): 'value => {
    _decoder(~fields=self.fields, ~construct=self.construct, ~decode=_decode)(unknown)
  }
}

let string = make(~kind=String, ())
let bool = make(~kind=Bool, ())
let int = make(~kind=Int, ())
let float = make(~kind=Float, ())

let field = (fieldName, fieldSchema) => {
  (fieldName, fieldSchema)
}

let array = struct => make(~kind=Array(struct), ())

external unsafeToOption: 'a => option<'a> = "%identity"
let option = struct => {
  make(
    ~kind=Option(struct),
    ~decoder=unknown => {
      unknown->unsafeToOption->Js.Option.map((. unknown') => _decode(struct, unknown'), _)
    },
    (),
  )
}

let record1 = (~fields, ~construct) => {
  let recordHelper = RecordHelper.make(~fields, ~construct)
  make(~kind=Record1(fields), ~decoder=recordHelper->RecordHelper.decoder, ())
}
let record2 = (~fields, ~construct) => {
  let recordHelper = RecordHelper.make(~fields, ~construct)
  make(~kind=Record2(fields), ~decoder=recordHelper->RecordHelper.decoder, ())
}
let record3 = (~fields, ~construct) => {
  let recordHelper = RecordHelper.make(~fields, ~construct)
  make(~kind=Record3(fields), ~decoder=recordHelper->RecordHelper.decoder, ())
}

module JsonSchema = {
  exception NestedOptionException
  exception RootOptionException

  type t<'value> = FJS.json<'value>
  type rec fluentSchema<'value> = FJS.t<'value>
  and meta<'value> =
    | Optional(fluentSchema<'value>)
    | Required(fluentSchema<option<'value>>)

  external unwrapRootValueType: fluentSchema<option<'value>> => fluentSchema<'value> = "%identity"

  let applyMetaData = (~isRecordField=true, meta: meta<'value>): fluentSchema<'value> => {
    switch (meta, isRecordField) {
    | (Optional(_), false) => raise(RootOptionException)
    | (Optional(fluentSchema), true) => fluentSchema
    | (Required(fluentSchema), false) => fluentSchema->unwrapRootValueType
    | (Required(fluentSchema), true) => fluentSchema->FJS.required()
    }
  }

  let rec makeMetaSchema:
    type src. struct<src> => meta<src> =
    struct => {
      switch struct.kind {
      | String => Required(FJS.string())
      | Int => Required(FJS.integer())
      | Bool => Required(FJS.boolean())
      | Float => Required(FJS.number())
      | Array(s') =>
        Required(FJS.array()->FJS.items(makeMetaSchema(s')->applyMetaData(~isRecordField=false)))
      | Option(s') =>
        switch makeMetaSchema(s') {
        | Optional(_) => raise(NestedOptionException)
        | Required(s'') => Optional(s'')
        }
      | Record1((fn1, fs1)) =>
        Required(FJS.object()->FJS.prop(fn1, makeMetaSchema(fs1)->applyMetaData))
      | Record2((fn1, fs1), (fn2, fs2)) =>
        Required(
          FJS.object()
          ->FJS.prop(fn1, makeMetaSchema(fs1)->applyMetaData)
          ->FJS.prop(fn2, makeMetaSchema(fs2)->applyMetaData),
        )
      | Record3((fn1, fs1), (fn2, fs2), (fn3, fs3)) =>
        Required(
          FJS.object()
          ->FJS.prop(fn1, makeMetaSchema(fs1)->applyMetaData)
          ->FJS.prop(fn2, makeMetaSchema(fs2)->applyMetaData)
          ->FJS.prop(fn3, makeMetaSchema(fs3)->applyMetaData),
        )
      }
    }

  let make = struct => {
    try {
      let fluentSchema = makeMetaSchema(struct)->applyMetaData(~isRecordField=false)
      fluentSchema->FJS.valueOf
    } catch {
    | NestedOptionException =>
      Js.Exn.raiseError("The option struct can't be nested in another option struct.")
    | RootOptionException => Js.Exn.raiseError("The root struct can't be optional.")
    // TODO: Handle FluentSchema error
    // TODO: Raise custom instance of error
    | _ => Js.Exn.raiseError("Unknown RescriptJsonSchema error.")
    }
  }
}
