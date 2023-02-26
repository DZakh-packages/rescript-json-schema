// Generated by ReScript, PLEASE EDIT WITH CARE
'use strict';

var Curry = require("rescript/lib/js/curry.js");
var Caml_option = require("rescript/lib/js/caml_option.js");
var Caml_exceptions = require("rescript/lib/js/caml_exceptions.js");
var S$ReScriptStruct = require("rescript-struct/src/S.bs.js");
var Caml_js_exceptions = require("rescript/lib/js/caml_js_exceptions.js");

var Exception = /* @__PURE__ */Caml_exceptions.create("JsonSchema.Error.Exception");

function raise(pathOpt, code) {
  var path = pathOpt !== undefined ? pathOpt : [];
  throw {
        RE_EXN_ID: Exception,
        _1: {
          code: code,
          path: path
        },
        Error: new Error()
      };
}

function raise$1(path, struct) {
  return raise(path, {
              TAG: /* UnsupportedOptionalItem */0,
              _0: S$ReScriptStruct.name(struct)
            });
}

function raise$2(path, struct) {
  return raise(path, {
              TAG: /* UnsupportedStruct */1,
              _0: S$ReScriptStruct.name(struct)
            });
}

function pathToText(path) {
  if (path.length !== 0) {
    return path.map(function (pathItem) {
                  return "[\"" + pathItem + "\"]";
                }).join("");
  } else {
    return "root";
  }
}

function prependLocation(error, $$location) {
  error.path = [$$location].concat(error.path);
  return error;
}

function toString(error) {
  var pathText = pathToText(error.path);
  var structName = error.code;
  var reason;
  if (typeof structName === "number") {
    reason = structName === /* UnsupportedNestedOptional */0 ? "Optional struct is not supported inside the Option struct" : "Optional struct is not supported at root";
  } else {
    switch (structName.TAG | 0) {
      case /* UnsupportedOptionalItem */0 :
          reason = "Optional struct is not supported as " + structName._0 + " item";
          break;
      case /* UnsupportedStruct */1 :
          reason = "The " + structName._0 + " struct is not supported";
          break;
      case /* DefaultDestructingFailed */2 :
          reason = "Couldn't destruct default value. Error: " + structName.destructingErrorMessage + "";
          break;
      
    }
  }
  return "[ReScript JSON Schema] Failed converting at " + pathText + ". Reason: " + reason + "";
}

var merge = ((s1, s2) => Object.assign({}, s1, s2));

var schemaDialect = {
  $schema: "http://json-schema.org/draft-07/schema#"
};

var empty = {};

var string = {
  type: "string"
};

var integer = {
  type: "integer"
};

var number = {
  type: "number"
};

var $$boolean = {
  type: "boolean"
};

function $$null(innerSchema) {
  return {
          anyOf: [
            innerSchema,
            {
              type: "null"
            }
          ]
        };
}

var never = {
  not: {}
};

function array(innerSchema) {
  return {
          items: innerSchema,
          type: "array"
        };
}

function tuple(items) {
  return {
          items: items,
          type: "array",
          minItems: items.length,
          maxItems: items.length
        };
}

function dict(innerSchema) {
  return {
          type: "object",
          additionalProperties: innerSchema
        };
}

function record(properties, additionalProperties, required) {
  var schema = {
    type: "object",
    properties: properties,
    additionalProperties: additionalProperties
  };
  if (required.length !== 0) {
    return merge(schema, {
                required: required
              });
  } else {
    return schema;
  }
}

var deprecated = {
  deprecated: true
};

function deprecatedWithMessage(message) {
  return {
          deprecated: true,
          description: message
        };
}

function string$1(value) {
  return {
          type: "string",
          const: value
        };
}

function integer$1(value) {
  return {
          type: "integer",
          const: value
        };
}

function number$1(value) {
  return {
          type: "number",
          const: value
        };
}

function $$boolean$1(value) {
  return {
          type: "boolean",
          const: value
        };
}

var $$null$1 = {
  type: "null"
};

var metadataId = Curry._2(S$ReScriptStruct.Metadata.Id.make, "rescript-json-schema", "raw");

function makeNode(struct) {
  var maybeMetadataRawSchema = S$ReScriptStruct.Metadata.get(struct, metadataId);
  var innerStruct = S$ReScriptStruct.classify(struct);
  var node;
  if (typeof innerStruct === "number") {
    switch (innerStruct) {
      case /* Never */0 :
          node = {
            rawSchema: never,
            isRequired: true
          };
          break;
      case /* Unknown */1 :
          node = {
            rawSchema: empty,
            isRequired: true
          };
          break;
      case /* String */2 :
          node = {
            rawSchema: string,
            isRequired: true
          };
          break;
      case /* Int */3 :
          node = {
            rawSchema: integer,
            isRequired: true
          };
          break;
      case /* Float */4 :
          node = {
            rawSchema: number,
            isRequired: true
          };
          break;
      case /* Bool */5 :
          node = {
            rawSchema: $$boolean,
            isRequired: true
          };
          break;
      
    }
  } else {
    switch (innerStruct.TAG | 0) {
      case /* Literal */0 :
          var value = innerStruct._0;
          if (typeof value === "number") {
            switch (value) {
              case /* EmptyNull */0 :
                  node = {
                    rawSchema: $$null$1,
                    isRequired: true
                  };
                  break;
              case /* EmptyOption */1 :
              case /* NaN */2 :
                  node = raise$2(undefined, struct);
                  break;
              
            }
          } else {
            switch (value.TAG | 0) {
              case /* String */0 :
                  node = {
                    rawSchema: string$1(value._0),
                    isRequired: true
                  };
                  break;
              case /* Int */1 :
                  node = {
                    rawSchema: integer$1(value._0),
                    isRequired: true
                  };
                  break;
              case /* Float */2 :
                  node = {
                    rawSchema: number$1(value._0),
                    isRequired: true
                  };
                  break;
              case /* Bool */3 :
                  node = {
                    rawSchema: $$boolean$1(value._0),
                    isRequired: true
                  };
                  break;
              
            }
          }
          break;
      case /* Option */1 :
          var innerNode = makeNode(innerStruct._0);
          node = innerNode.isRequired ? ({
                rawSchema: innerNode.rawSchema,
                isRequired: false
              }) : raise(undefined, /* UnsupportedNestedOptional */0);
          break;
      case /* Null */2 :
          var innerNode$1 = makeNode(innerStruct._0);
          node = innerNode$1.isRequired ? ({
                rawSchema: $$null(innerNode$1.rawSchema),
                isRequired: true
              }) : raise$1(undefined, struct);
          break;
      case /* Array */3 :
          var innerNode$2 = makeNode(innerStruct._0);
          node = innerNode$2.isRequired ? ({
                rawSchema: array(innerNode$2.rawSchema),
                isRequired: true
              }) : raise$1(undefined, struct);
          break;
      case /* Object */4 :
          var fieldNames = innerStruct.fieldNames;
          var fields = innerStruct.fields;
          var fieldNodes = fieldNames.map(function (fieldName) {
                var fieldStruct = fields[fieldName];
                try {
                  return makeNode(fieldStruct);
                }
                catch (raw_error){
                  var error = Caml_js_exceptions.internalToOCamlException(raw_error);
                  if (error.RE_EXN_ID === Exception) {
                    throw {
                          RE_EXN_ID: Exception,
                          _1: prependLocation(error._1, fieldName),
                          Error: new Error()
                        };
                  }
                  throw error;
                }
              });
          var properties = {};
          var required = [];
          fieldNodes.forEach(function (fieldNode, idx) {
                var fieldName = fieldNames[idx];
                if (fieldNode.isRequired) {
                  required.push(fieldName);
                }
                properties[fieldName] = fieldNode.rawSchema;
              });
          var match = Curry._1(S$ReScriptStruct.$$Object.UnknownKeys.classify, struct);
          var rawSchema = record(properties, match ? true : false, required);
          node = {
            rawSchema: rawSchema,
            isRequired: true
          };
          break;
      case /* Tuple */5 :
          var items = innerStruct._0.map(function (innerStruct, idx) {
                var innerNode = makeNode(innerStruct);
                if (innerNode.isRequired) {
                  return innerNode.rawSchema;
                } else {
                  return raise$1([idx.toString()], struct);
                }
              });
          node = {
            rawSchema: tuple(items),
            isRequired: true
          };
          break;
      case /* Union */6 :
          var items$1 = innerStruct._0.map(function (innerStruct) {
                var innerNode = makeNode(innerStruct);
                if (innerNode.isRequired) {
                  return innerNode.rawSchema;
                } else {
                  return raise$1(undefined, struct);
                }
              });
          node = {
            rawSchema: {
              anyOf: items$1
            },
            isRequired: true
          };
          break;
      case /* Dict */7 :
          var innerNode$3 = makeNode(innerStruct._0);
          node = innerNode$3.isRequired ? ({
                rawSchema: dict(innerNode$3.rawSchema),
                isRequired: true
              }) : raise$1(undefined, struct);
          break;
      
    }
  }
  var match$1 = S$ReScriptStruct.Deprecated.classify(struct);
  var rawSchema$1 = match$1 !== undefined ? (
      match$1 ? merge(node.rawSchema, deprecatedWithMessage(match$1._0)) : merge(node.rawSchema, deprecated)
    ) : node.rawSchema;
  var node_isRequired = node.isRequired;
  var node$1 = {
    rawSchema: rawSchema$1,
    isRequired: node_isRequired
  };
  var match$2 = S$ReScriptStruct.Defaulted.classify(struct);
  var node$2;
  if (match$2 !== undefined) {
    var destructingError = S$ReScriptStruct.serializeWith(Caml_option.some(match$2._0), struct);
    node$2 = destructingError.TAG === /* Ok */0 ? ({
          rawSchema: merge(rawSchema$1, {
                default: destructingError._0
              }),
          isRequired: false
        }) : raise(undefined, {
            TAG: /* DefaultDestructingFailed */2,
            destructingErrorMessage: S$ReScriptStruct.$$Error.toString(destructingError._0)
          });
  } else {
    node$2 = node$1;
  }
  var rawSchema$2 = maybeMetadataRawSchema !== undefined ? merge(node$2.rawSchema, Caml_option.valFromOption(maybeMetadataRawSchema)) : node$2.rawSchema;
  return {
          rawSchema: rawSchema$2,
          isRequired: node$2.isRequired
        };
}

function make(struct) {
  try {
    var node = makeNode(struct);
    if (node.isRequired) {
      return {
              TAG: /* Ok */0,
              _0: merge(node.rawSchema, schemaDialect)
            };
    } else {
      return raise(undefined, /* UnsupportedRootOptional */1);
    }
  }
  catch (raw_error){
    var error = Caml_js_exceptions.internalToOCamlException(raw_error);
    if (error.RE_EXN_ID === Exception) {
      return {
              TAG: /* Error */1,
              _0: toString(error._1)
            };
    }
    throw error;
  }
}

function raw(struct, providedRawSchema) {
  var existingRawSchema = S$ReScriptStruct.Metadata.get(struct, metadataId);
  var rawSchema = existingRawSchema !== undefined ? merge(Caml_option.valFromOption(existingRawSchema), providedRawSchema) : providedRawSchema;
  return S$ReScriptStruct.Metadata.set(struct, metadataId, rawSchema);
}

function description(struct, value) {
  return raw(struct, {
              description: value
            });
}

exports.make = make;
exports.raw = raw;
exports.description = description;
/* metadataId Not a pure module */
