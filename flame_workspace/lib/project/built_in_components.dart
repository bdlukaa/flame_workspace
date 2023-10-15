/// Automatically generated file.
/// Do not edit manually

import 'game_objects.dart';

final builtInComponents = [
  FlameComponentObject(
    name: 'FpsTextComponent',
    type: 'TextComponent',
    parameters: [
      FlameComponentField('windowSize', 'int', '60'),
      FlameComponentField('decimalPlaces', 'int', '0'),
      FlameComponentField('super.textRenderer', 'dynamic', 'null'),
      FlameComponentField('super.position', 'dynamic', 'null'),
      FlameComponentField('super.size', 'dynamic', 'null'),
      FlameComponentField('super.scale', 'dynamic', 'null'),
      FlameComponentField('super.angle', 'dynamic', 'null'),
      FlameComponentField('super.anchor', 'dynamic', 'null'),
      FlameComponentField('priority', 'int?', 'null')
    ],
    data: {
      "kind": "class",
      "name": "FpsTextComponent",
      "typeParameters": [
        {"name": "T", "extends": "TextRenderer"}
      ],
      "extends": "TextComponent",
      "members": [
        {
          "kind": "constructor",
          "name": "FpsTextComponent",
          "parameters": {
            "all": [
              {"name": "windowSize", "type": "int", "default": "60"},
              {"name": "this.decimalPlaces", "default": "0"},
              {"name": "super.textRenderer"},
              {"name": "super.position"},
              {"name": "super.size"},
              {"name": "super.scale"},
              {"name": "super.angle"},
              {"name": "super.anchor"},
              {"name": "priority", "type": "int?"}
            ],
            "named": 9
          }
        },
        {
          "kind": "field",
          "name": "decimalPlaces",
          "type": "int",
          "final": true
        },
        {
          "kind": "field",
          "name": "fpsComponent",
          "type": "FpsComponent",
          "final": true
        },
        {
          "kind": "method",
          "name": "update",
          "parameters": {
            "all": [
              {"name": "dt", "type": "double"}
            ]
          },
          "returns": "void",
          "annotations": [
            {"name": "@override"}
          ]
        }
      ]
    },
  )..components = [
      FlameComponentObject(
        name: 'FpsComponent',
        type: 'Component',
        parameters: [
          FlameComponentField('windowSize', 'int', '60'),
          FlameComponentField('super.key', 'dynamic', 'null')
        ],
        data: {
          "kind": "class",
          "name": "FpsComponent",
          "extends": "Component",
          "members": [
            {
              "kind": "constructor",
              "name": "FpsComponent",
              "parameters": {
                "all": [
                  {"name": "this.windowSize", "default": "60"},
                  {"name": "super.key"}
                ],
                "named": 2
              }
            },
            {
              "kind": "field",
              "name": "windowSize",
              "type": "int",
              "description":
                  "The sliding window size, i.e. the number of game ticks over which the fps\nmeasure will be averaged.\n",
              "final": true
            },
            {
              "kind": "field",
              "name": "window",
              "type": "Queue<double>",
              "description":
                  "The queue of the recent game tick durations.\nThe length of this queue will not exceed [windowSize].\n",
              "final": true
            },
            {
              "kind": "method",
              "name": "update",
              "parameters": {
                "all": [
                  {"name": "dt", "type": "double"}
                ]
              },
              "returns": "void",
              "annotations": [
                {"name": "@override"}
              ]
            },
            {
              "kind": "getter",
              "name": "fps",
              "description":
                  "Get the current average FPS over the last [windowSize] frames.\n",
              "returns": "double"
            }
          ]
        },
      )..components = []
    ],
  FlameComponentObject(
    name: 'KeyboardListenerComponent',
    type: 'Component',
    parameters: [
      FlameComponentField(
          'keyUp', 'Map<LogicalKeyboardKey, KeyHandlerCallback>', 'const {}'),
      FlameComponentField(
          'keyDown', 'Map<LogicalKeyboardKey, KeyHandlerCallback>', 'const {}')
    ],
    data: {
      "kind": "class",
      "name": "KeyboardListenerComponent",
      "extends": "Component",
      "with": ["KeyboardHandler"],
      "members": [
        {
          "kind": "constructor",
          "name": "KeyboardListenerComponent",
          "description": "{@macro keyboard_listener_component}\n",
          "parameters": {
            "all": [
              {
                "name": "keyUp",
                "type": "Map<LogicalKeyboardKey, KeyHandlerCallback>",
                "default": "const {}"
              },
              {
                "name": "keyDown",
                "type": "Map<LogicalKeyboardKey, KeyHandlerCallback>",
                "default": "const {}"
              }
            ],
            "named": 2
          }
        },
        {
          "kind": "method",
          "name": "onKeyEvent",
          "parameters": {
            "all": [
              {"name": "event", "type": "RawKeyEvent"},
              {"name": "keysPressed", "type": "Set<LogicalKeyboardKey>"}
            ]
          },
          "returns": "bool",
          "annotations": [
            {"name": "@override"}
          ]
        }
      ]
    },
  )..components = [],
  FlameComponentObject(
    name: 'ShapeComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('super.position', 'dynamic', 'null'),
      FlameComponentField('super.size', 'dynamic', 'null'),
      FlameComponentField('super.scale', 'dynamic', 'null'),
      FlameComponentField('super.angle', 'dynamic', 'null'),
      FlameComponentField('super.anchor', 'dynamic', 'null'),
      FlameComponentField('super.children', 'dynamic', 'null'),
      FlameComponentField('super.priority', 'dynamic', 'null'),
      FlameComponentField('super.key', 'dynamic', 'null'),
      FlameComponentField('paint', 'Paint?', 'null'),
      FlameComponentField('paintLayers', 'List<Paint>?', 'null')
    ],
    data: {
      "kind": "class",
      "name": "ShapeComponent",
      "abstract": true,
      "extends": "PositionComponent",
      "with": ["HasPaint"],
      "members": [
        {
          "kind": "constructor",
          "name": "ShapeComponent",
          "parameters": {
            "all": [
              {"name": "super.position"},
              {"name": "super.size"},
              {"name": "super.scale"},
              {"name": "super.angle"},
              {"name": "super.anchor"},
              {"name": "super.children"},
              {"name": "super.priority"},
              {"name": "super.key"},
              {"name": "paint", "type": "Paint?"},
              {"name": "paintLayers", "type": "List<Paint>?"}
            ],
            "named": 10
          }
        },
        {"kind": "field", "name": "renderShape", "type": "bool"},
        {
          "kind": "field",
          "name": "isSolid",
          "type": "bool",
          "description":
              "Whether the shape is solid or hollow.\n\nIf it is solid, intersections will occur even if the other component is\nfully enclosed by the other hitbox. The intersection point in such cases\nwill be the center of the enclosed [ShapeComponent].\nA hollow shape that is fully enclosed by a solid hitbox will cause an\nintersection result, but not the other way around.\n\nThis field is not related to how the shape should be rendered, see\n[Paint.style] for that.\n"
        }
      ]
    },
  )..components = [],
  FlameComponentObject(
    name: 'ScreenHitbox',
    type: 'PositionComponent',
    parameters: [],
    data: {
      "kind": "class",
      "name": "ScreenHitbox",
      "typeParameters": [
        {"name": "T", "extends": "FlameGame"}
      ],
      "extends": "PositionComponent",
      "with": ["CollisionCallbacks", "HasGameReference<T>"],
      "members": [
        {
          "kind": "method",
          "name": "onLoad",
          "returns": "Future<void>",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "onGameResize",
          "parameters": {
            "all": [
              {"name": "size", "type": "Vector2"}
            ]
          },
          "returns": "void",
          "annotations": [
            {"name": "@override"}
          ]
        }
      ]
    },
  )..components = [],
  FlameComponentObject(
    name: 'TimerComponent',
    type: 'Component',
    parameters: [
      FlameComponentField('period', 'double', 'null'),
      FlameComponentField('repeat', 'bool', 'false'),
      FlameComponentField('autoStart', 'bool', 'true'),
      FlameComponentField('removeOnFinish', 'bool', 'false'),
      FlameComponentField('onTick', 'VoidCallback?', 'null'),
      FlameComponentField('super.key', 'dynamic', 'null')
    ],
    data: {
      "kind": "class",
      "name": "TimerComponent",
      "extends": "Component",
      "members": [
        {
          "kind": "field",
          "name": "timer",
          "type": "Timer",
          "final": true,
          "late": true
        },
        {
          "kind": "field",
          "name": "removeOnFinish",
          "type": "bool",
          "final": true
        },
        {
          "kind": "constructor",
          "name": "TimerComponent",
          "description":
              "Creates a [TimerComponent]\n\n[period] The period of time in seconds that the tick will be called\n[repeat] When true, this will continue running after [period] is reached\n[autoStart] When true, will start upon instantiation (default is true)\n[onTick] When provided, will be called every time [period] is reached.\nThis overrides the [onTick] method\n",
          "parameters": {
            "all": [
              {"name": "period", "type": "double", "required": true},
              {"name": "repeat", "type": "bool", "default": "false"},
              {"name": "autoStart", "type": "bool", "default": "true"},
              {"name": "this.removeOnFinish", "default": "false"},
              {"name": "onTick", "type": "VoidCallback?"},
              {"name": "super.key"}
            ],
            "named": 6
          }
        },
        {
          "kind": "method",
          "name": "onTick",
          "description":
              "Called every time the [timer] reached a tick.\nThe default implementation calls the closure received on the\nconstructor and can be overridden to add custom logic.\n",
          "returns": "void"
        },
        {
          "kind": "method",
          "name": "update",
          "parameters": {
            "all": [
              {"name": "dt", "type": "double"}
            ]
          },
          "returns": "void",
          "annotations": [
            {"name": "@override"}
          ]
        }
      ]
    },
  )..components = [],
  FlameComponentObject(
    name: 'FpsComponent',
    type: 'Component',
    parameters: [
      FlameComponentField('windowSize', 'int', '60'),
      FlameComponentField('super.key', 'dynamic', 'null')
    ],
    data: {
      "kind": "class",
      "name": "FpsComponent",
      "extends": "Component",
      "members": [
        {
          "kind": "constructor",
          "name": "FpsComponent",
          "parameters": {
            "all": [
              {"name": "this.windowSize", "default": "60"},
              {"name": "super.key"}
            ],
            "named": 2
          }
        },
        {
          "kind": "field",
          "name": "windowSize",
          "type": "int",
          "description":
              "The sliding window size, i.e. the number of game ticks over which the fps\nmeasure will be averaged.\n",
          "final": true
        },
        {
          "kind": "field",
          "name": "window",
          "type": "Queue<double>",
          "description":
              "The queue of the recent game tick durations.\nThe length of this queue will not exceed [windowSize].\n",
          "final": true
        },
        {
          "kind": "method",
          "name": "update",
          "parameters": {
            "all": [
              {"name": "dt", "type": "double"}
            ]
          },
          "returns": "void",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "getter",
          "name": "fps",
          "description":
              "Get the current average FPS over the last [windowSize] frames.\n",
          "returns": "double"
        }
      ]
    },
  )..components = [],
  FlameComponentObject(
    name: 'ClipComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('builder', 'ShapeBuilder', 'null'),
      FlameComponentField('super.position', 'dynamic', 'null'),
      FlameComponentField('super.size', 'dynamic', 'null'),
      FlameComponentField('super.scale', 'dynamic', 'null'),
      FlameComponentField('super.angle', 'dynamic', 'null'),
      FlameComponentField('super.anchor', 'dynamic', 'null'),
      FlameComponentField('super.children', 'dynamic', 'null'),
      FlameComponentField('super.priority', 'dynamic', 'null'),
      FlameComponentField('super.key', 'dynamic', 'null'),
      FlameComponentField('position', 'Vector2?', 'null'),
      FlameComponentField('size', 'Vector2?', 'null'),
      FlameComponentField('scale', 'Vector2?', 'null'),
      FlameComponentField('angle', 'double?', 'null'),
      FlameComponentField('anchor', 'Anchor?', 'null'),
      FlameComponentField('children', 'Iterable<Component>?', 'null'),
      FlameComponentField('priority', 'int?', 'null'),
      FlameComponentField('key', 'ComponentKey?', 'null'),
      FlameComponentField('position', 'Vector2?', 'null'),
      FlameComponentField('size', 'Vector2?', 'null'),
      FlameComponentField('scale', 'Vector2?', 'null'),
      FlameComponentField('angle', 'double?', 'null'),
      FlameComponentField('anchor', 'Anchor?', 'null'),
      FlameComponentField('children', 'Iterable<Component>?', 'null'),
      FlameComponentField('priority', 'int?', 'null'),
      FlameComponentField('key', 'ComponentKey?', 'null'),
      FlameComponentField('points', 'List<Vector2>', 'null'),
      FlameComponentField('position', 'Vector2?', 'null'),
      FlameComponentField('size', 'Vector2?', 'null'),
      FlameComponentField('scale', 'Vector2?', 'null'),
      FlameComponentField('angle', 'double?', 'null'),
      FlameComponentField('anchor', 'Anchor?', 'null'),
      FlameComponentField('children', 'Iterable<Component>?', 'null'),
      FlameComponentField('priority', 'int?', 'null'),
      FlameComponentField('key', 'ComponentKey?', 'null')
    ],
    data: {
      "kind": "class",
      "name": "ClipComponent",
      "extends": "PositionComponent",
      "implements": ["SizeProvider"],
      "members": [
        {
          "kind": "constructor",
          "name": "ClipComponent",
          "description":
              "{@macro clip_component}\n\nClips the canvas based its shape and size.\n",
          "parameters": {
            "all": [
              {"name": "builder", "type": "ShapeBuilder", "required": true},
              {"name": "super.position"},
              {"name": "super.size"},
              {"name": "super.scale"},
              {"name": "super.angle"},
              {"name": "super.anchor"},
              {"name": "super.children"},
              {"name": "super.priority"},
              {"name": "super.key"}
            ],
            "named": 9
          }
        },
        {
          "kind": "constructor",
          "name": "ClipComponent.circle",
          "factory": true,
          "description":
              "{@macro circle_clip_component}\n\nClips the canvas in the form of a circle based on its size.\n",
          "parameters": {
            "all": [
              {"name": "position", "type": "Vector2?"},
              {"name": "size", "type": "Vector2?"},
              {"name": "scale", "type": "Vector2?"},
              {"name": "angle", "type": "double?"},
              {"name": "anchor", "type": "Anchor?"},
              {"name": "children", "type": "Iterable<Component>?"},
              {"name": "priority", "type": "int?"},
              {"name": "key", "type": "ComponentKey?"}
            ],
            "named": 8
          }
        },
        {
          "kind": "constructor",
          "name": "ClipComponent.rectangle",
          "factory": true,
          "description":
              "{@macro rectangle_clip_component}\n\nClips the canvas in the form of a rectangle based on its size.\n",
          "parameters": {
            "all": [
              {"name": "position", "type": "Vector2?"},
              {"name": "size", "type": "Vector2?"},
              {"name": "scale", "type": "Vector2?"},
              {"name": "angle", "type": "double?"},
              {"name": "anchor", "type": "Anchor?"},
              {"name": "children", "type": "Iterable<Component>?"},
              {"name": "priority", "type": "int?"},
              {"name": "key", "type": "ComponentKey?"}
            ],
            "named": 8
          }
        },
        {
          "kind": "constructor",
          "name": "ClipComponent.polygon",
          "factory": true,
          "description":
              "{@macro polygon_clip_component}\n\nClips the canvas in the form of a polygon based on its size.\n",
          "parameters": {
            "all": [
              {"name": "points", "type": "List<Vector2>", "required": true},
              {"name": "position", "type": "Vector2?"},
              {"name": "size", "type": "Vector2?"},
              {"name": "scale", "type": "Vector2?"},
              {"name": "angle", "type": "double?"},
              {"name": "anchor", "type": "Anchor?"},
              {"name": "children", "type": "Iterable<Component>?"},
              {"name": "priority", "type": "int?"},
              {"name": "key", "type": "ComponentKey?"}
            ],
            "named": 9
          }
        },
        {
          "kind": "method",
          "name": "onLoad",
          "returns": "Future<void>",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "render",
          "parameters": {
            "all": [
              {"name": "canvas", "type": "Canvas"}
            ]
          },
          "returns": "void",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "containsPoint",
          "parameters": {
            "all": [
              {"name": "point", "type": "Vector2"}
            ]
          },
          "returns": "bool",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "containsLocalPoint",
          "parameters": {
            "all": [
              {"name": "point", "type": "Vector2"}
            ]
          },
          "returns": "bool",
          "annotations": [
            {"name": "@override"}
          ]
        }
      ]
    },
  )..components = [],
  FlameComponentObject(
    name: 'World',
    type: 'Component',
    parameters: [
      FlameComponentField('super.children', 'dynamic', 'null'),
      FlameComponentField('super.priority', 'dynamic', '-0x7fffffff')
    ],
    data: {
      "kind": "class",
      "name": "World",
      "extends": "Component",
      "implements": ["CoordinateTransform"],
      "members": [
        {
          "kind": "constructor",
          "name": "World",
          "parameters": {
            "all": [
              {"name": "super.children"},
              {"name": "super.priority", "default": "-0x7fffffff"}
            ],
            "named": 2
          }
        },
        {
          "kind": "method",
          "name": "renderTree",
          "parameters": {
            "all": [
              {"name": "canvas", "type": "Canvas"}
            ]
          },
          "returns": "void",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "containsLocalPoint",
          "parameters": {
            "all": [
              {"name": "point", "type": "Vector2"}
            ]
          },
          "returns": "bool",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "localToParent",
          "parameters": {
            "all": [
              {"name": "point", "type": "Vector2"}
            ]
          },
          "returns": "Vector2?",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "parentToLocal",
          "parameters": {
            "all": [
              {"name": "point", "type": "Vector2"}
            ]
          },
          "returns": "Vector2?",
          "annotations": [
            {"name": "@override"}
          ]
        }
      ]
    },
  )..components = [],
  FlameComponentObject(
    name: 'SpriteBatchComponent',
    type: 'Component',
    parameters: [
      FlameComponentField('spriteBatch', 'SpriteBatch?', 'null'),
      FlameComponentField('blendMode', 'BlendMode?', 'null'),
      FlameComponentField('cullRect', 'Rect?', 'null'),
      FlameComponentField('paint', 'Paint?', 'null'),
      FlameComponentField('super.key', 'dynamic', 'null')
    ],
    data: {
      "kind": "class",
      "name": "SpriteBatchComponent",
      "extends": "Component",
      "members": [
        {"kind": "field", "name": "spriteBatch", "type": "SpriteBatch?"},
        {"kind": "field", "name": "blendMode", "type": "BlendMode?"},
        {"kind": "field", "name": "cullRect", "type": "Rect?"},
        {"kind": "field", "name": "paint", "type": "Paint?"},
        {
          "kind": "constructor",
          "name": "SpriteBatchComponent",
          "description":
              "Creates a component with an empty sprite batch which can be set later\n",
          "parameters": {
            "all": [
              {"name": "this.spriteBatch"},
              {"name": "this.blendMode"},
              {"name": "this.cullRect"},
              {"name": "this.paint"},
              {"name": "super.key"}
            ],
            "named": 5
          }
        },
        {
          "kind": "method",
          "name": "onMount",
          "returns": "void",
          "annotations": [
            {"name": "@override"},
            {"name": "@mustCallSuper"}
          ]
        },
        {
          "kind": "method",
          "name": "render",
          "parameters": {
            "all": [
              {"name": "canvas", "type": "Canvas"}
            ]
          },
          "returns": "void",
          "annotations": [
            {"name": "@mustCallSuper"},
            {"name": "@override"}
          ]
        }
      ]
    },
  )..components = [],
  FlameComponentObject(
    name: 'SpawnComponent',
    type: 'Component',
    parameters: [
      FlameComponentField(
          'factory', 'PositionComponent Function(int amount)', 'null'),
      FlameComponentField('period', 'double', 'null'),
      FlameComponentField('area', 'Shape?', 'null'),
      FlameComponentField('within', 'bool', 'true'),
      FlameComponentField('random', 'Random?', 'null'),
      FlameComponentField('super.key', 'dynamic', 'null'),
      FlameComponentField(
          'factory', 'PositionComponent Function(int amount)', 'null'),
      FlameComponentField('minPeriod', 'double', 'null'),
      FlameComponentField('maxPeriod', 'double', 'null'),
      FlameComponentField('area', 'Shape?', 'null'),
      FlameComponentField('within', 'bool', 'true'),
      FlameComponentField('random', 'Random?', 'null'),
      FlameComponentField('super.key', 'dynamic', 'null')
    ],
    data: {
      "kind": "class",
      "name": "SpawnComponent",
      "extends": "Component",
      "members": [
        {
          "kind": "constructor",
          "name": "SpawnComponent",
          "description": "{@macro spawn_component}\n",
          "parameters": {
            "all": [
              {"name": "this.factory", "required": true},
              {"name": "period", "type": "double", "required": true},
              {"name": "this.area"},
              {"name": "this.within", "default": "true"},
              {"name": "random", "type": "Random?"},
              {"name": "super.key"}
            ],
            "named": 6
          }
        },
        {
          "kind": "constructor",
          "name": "SpawnComponent.periodRange",
          "description":
              "Use this constructor if you want your components to spawn within an\ninterval time range.\n[minPeriod] will be the minimum amount of time before the next component\nspawns and [maxPeriod] will be the maximum amount of time before it\nspawns.\n",
          "parameters": {
            "all": [
              {"name": "this.factory", "required": true},
              {"name": "minPeriod", "type": "double", "required": true},
              {"name": "maxPeriod", "type": "double", "required": true},
              {"name": "this.area"},
              {"name": "this.within", "default": "true"},
              {"name": "random", "type": "Random?"},
              {"name": "super.key"}
            ],
            "named": 7
          }
        },
        {
          "kind": "field",
          "name": "factory",
          "type": "PositionComponent Function(int amount)",
          "description":
              "The function used to create new components to spawn.\n\n[amount] is the amount of components that the [SpawnComponent] has spawned\nso far.\n"
        },
        {
          "kind": "field",
          "name": "area",
          "type": "Shape?",
          "description": "The area where the components should be spawned.\n"
        },
        {
          "kind": "field",
          "name": "within",
          "type": "bool",
          "description":
              "Whether the random point should be within the [area] or along its edges.\n"
        },
        {
          "kind": "field",
          "name": "timer",
          "type": "Timer",
          "description":
              "The timer that is used to control when components are spawned.\n",
          "final": true,
          "late": true
        },
        {
          "kind": "getter",
          "name": "period",
          "description": "The time between each component is spawned.\n",
          "returns": "double"
        },
        {
          "kind": "setter",
          "name": "period",
          "parameters": {
            "all": [
              {"name": "newPeriod", "type": "double"}
            ]
          }
        },
        {
          "kind": "field",
          "name": "minPeriod",
          "type": "double?",
          "description":
              "The minimum amount of time that has to pass until the next component is\nspawned.\n"
        },
        {
          "kind": "field",
          "name": "maxPeriod",
          "type": "double?",
          "description":
              "The maximum amount of time that has to pass until the next component is\nspawned.\n"
        },
        {
          "kind": "getter",
          "name": "hasRandomPeriod",
          "description":
              "Whether it is spawning components within a random time frame or at a\nstatic rate.\n",
          "returns": "bool"
        },
        {
          "kind": "field",
          "name": "amount",
          "type": "int",
          "description": "The amount of spawned components.\n"
        },
        {
          "kind": "method",
          "name": "onLoad",
          "returns": "FutureOr<void>",
          "annotations": [
            {"name": "@override"}
          ]
        }
      ]
    },
  )..components = [],
  FlameComponentObject(
    name: 'ParticleSystemComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('particle', 'Particle?', 'null'),
      FlameComponentField('super.position', 'dynamic', 'null'),
      FlameComponentField('super.size', 'dynamic', 'null'),
      FlameComponentField('super.scale', 'dynamic', 'null'),
      FlameComponentField('super.angle', 'dynamic', 'null'),
      FlameComponentField('super.anchor', 'dynamic', 'null'),
      FlameComponentField('super.priority', 'dynamic', 'null'),
      FlameComponentField('super.key', 'dynamic', 'null')
    ],
    data: {
      "kind": "class",
      "name": "ParticleSystemComponent",
      "extends": "PositionComponent",
      "members": [
        {"kind": "field", "name": "particle", "type": "Particle?"},
        {
          "kind": "constructor",
          "name": "ParticleSystemComponent",
          "description": "{@macro particle_system_component}\n",
          "parameters": {
            "all": [
              {"name": "this.particle"},
              {"name": "super.position"},
              {"name": "super.size"},
              {"name": "super.scale"},
              {"name": "super.angle"},
              {"name": "super.anchor"},
              {"name": "super.priority"},
              {"name": "super.key"}
            ],
            "named": 8
          }
        },
        {
          "kind": "getter",
          "name": "progress",
          "description":
              "Returns progress of the child [Particle].\n\nCould be used by external code if needed.\n",
          "returns": "double"
        },
        {
          "kind": "method",
          "name": "render",
          "description":
              "Passes rendering chain down to the inset\n[Particle] within this [Component].\n",
          "parameters": {
            "all": [
              {"name": "canvas", "type": "Canvas"}
            ]
          },
          "returns": "void",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "update",
          "description": "Passes update chain to child [Particle].\n",
          "parameters": {
            "all": [
              {"name": "dt", "type": "double"}
            ]
          },
          "returns": "void",
          "annotations": [
            {"name": "@override"}
          ]
        }
      ]
    },
  )..components = [],
  FlameComponentObject(
    name: 'NineTileBoxComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('nineTileBox', 'NineTileBox?', 'null'),
      FlameComponentField('super.position', 'dynamic', 'null'),
      FlameComponentField('super.size', 'dynamic', 'null'),
      FlameComponentField('super.scale', 'dynamic', 'null'),
      FlameComponentField('super.angle', 'dynamic', 'null'),
      FlameComponentField('super.anchor', 'dynamic', 'null'),
      FlameComponentField('super.children', 'dynamic', 'null'),
      FlameComponentField('super.priority', 'dynamic', 'null'),
      FlameComponentField('super.key', 'dynamic', 'null')
    ],
    data: {
      "kind": "class",
      "name": "NineTileBoxComponent",
      "extends": "PositionComponent",
      "implements": ["SizeProvider"],
      "members": [
        {"kind": "field", "name": "nineTileBox", "type": "NineTileBox?"},
        {
          "kind": "constructor",
          "name": "NineTileBoxComponent",
          "description":
              "Takes the [NineTileBox] instance to render a box that can grow and shrink\nseamlessly.\n\nIt uses the x, y, width and height coordinates from the\n[PositionComponent] to render.\n",
          "parameters": {
            "all": [
              {"name": "this.nineTileBox"},
              {"name": "super.position"},
              {"name": "super.size"},
              {"name": "super.scale"},
              {"name": "super.angle"},
              {"name": "super.anchor"},
              {"name": "super.children"},
              {"name": "super.priority"},
              {"name": "super.key"}
            ],
            "named": 9
          }
        },
        {
          "kind": "method",
          "name": "onMount",
          "returns": "void",
          "annotations": [
            {"name": "@override"},
            {"name": "@mustCallSuper"}
          ]
        },
        {
          "kind": "method",
          "name": "render",
          "parameters": {
            "all": [
              {"name": "canvas", "type": "Canvas"}
            ]
          },
          "returns": "void",
          "annotations": [
            {"name": "@mustCallSuper"},
            {"name": "@override"}
          ]
        }
      ]
    },
  )..components = [],
  FlameComponentObject(
    name: 'TextElementComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('element', 'TextElement', 'null'),
      FlameComponentField('super.position', 'dynamic', 'null'),
      FlameComponentField('super.size', 'dynamic', 'null'),
      FlameComponentField('super.scale', 'dynamic', 'null'),
      FlameComponentField('super.angle', 'dynamic', 'null'),
      FlameComponentField('super.anchor', 'dynamic', 'null'),
      FlameComponentField('super.children', 'dynamic', 'null'),
      FlameComponentField('super.priority', 'dynamic', 'null'),
      FlameComponentField('super.key', 'dynamic', 'null'),
      FlameComponentField('document', 'DocumentRoot', 'null'),
      FlameComponentField('style', 'DocumentStyle?', 'null'),
      FlameComponentField('position', 'Vector2?', 'null'),
      FlameComponentField('size', 'Vector2?', 'null'),
      FlameComponentField('scale', 'Vector2?', 'null'),
      FlameComponentField('angle', 'double?', 'null'),
      FlameComponentField('anchor', 'Anchor?', 'null'),
      FlameComponentField('children', 'List<Component>?', 'null'),
      FlameComponentField('priority', 'int', '0'),
      FlameComponentField('key', 'ComponentKey?', 'null')
    ],
    data: {
      "kind": "class",
      "name": "TextElementComponent",
      "extends": "PositionComponent",
      "members": [
        {"kind": "field", "name": "element", "type": "TextElement"},
        {
          "kind": "constructor",
          "name": "TextElementComponent",
          "parameters": {
            "all": [
              {"name": "this.element", "required": true},
              {"name": "super.position"},
              {"name": "super.size"},
              {"name": "super.scale"},
              {"name": "super.angle"},
              {"name": "super.anchor"},
              {"name": "super.children"},
              {"name": "super.priority"},
              {"name": "super.key"}
            ],
            "named": 9
          }
        },
        {
          "kind": "constructor",
          "name": "TextElementComponent.fromDocument",
          "factory": true,
          "parameters": {
            "all": [
              {"name": "document", "type": "DocumentRoot", "required": true},
              {"name": "style", "type": "DocumentStyle?"},
              {"name": "position", "type": "Vector2?"},
              {"name": "size", "type": "Vector2?"},
              {"name": "scale", "type": "Vector2?"},
              {"name": "angle", "type": "double?"},
              {"name": "anchor", "type": "Anchor?"},
              {"name": "children", "type": "List<Component>?"},
              {"name": "priority", "type": "int", "default": "0"},
              {"name": "key", "type": "ComponentKey?"}
            ],
            "named": 10
          }
        },
        {
          "kind": "method",
          "name": "render",
          "parameters": {
            "all": [
              {"name": "canvas", "type": "Canvas"}
            ]
          },
          "returns": "void",
          "annotations": [
            {"name": "@override"}
          ]
        }
      ]
    },
  )..components = [],
  FlameComponentObject(
    name: 'CustomPainterComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('painter', 'CustomPainter?', 'null'),
      FlameComponentField('super.position', 'dynamic', 'null'),
      FlameComponentField('super.size', 'dynamic', 'null'),
      FlameComponentField('super.scale', 'dynamic', 'null'),
      FlameComponentField('super.angle', 'dynamic', 'null'),
      FlameComponentField('super.anchor', 'dynamic', 'null'),
      FlameComponentField('super.children', 'dynamic', 'null'),
      FlameComponentField('super.priority', 'dynamic', 'null')
    ],
    data: {
      "kind": "class",
      "name": "CustomPainterComponent",
      "extends": "PositionComponent",
      "implements": ["SizeProvider"],
      "members": [
        {
          "kind": "field",
          "name": "painter",
          "type": "CustomPainter?",
          "description": "The [CustomPainter] used to render this component\n"
        },
        {
          "kind": "constructor",
          "name": "CustomPainterComponent",
          "parameters": {
            "all": [
              {"name": "this.painter"},
              {"name": "super.position"},
              {"name": "super.size"},
              {"name": "super.scale"},
              {"name": "super.angle"},
              {"name": "super.anchor"},
              {"name": "super.children"},
              {"name": "super.priority"}
            ],
            "named": 8
          }
        },
        {
          "kind": "method",
          "name": "render",
          "parameters": {
            "all": [
              {"name": "canvas", "type": "Canvas"}
            ]
          },
          "returns": "void",
          "annotations": [
            {"name": "@override"},
            {"name": "@mustCallSuper"}
          ]
        }
      ]
    },
  )..components = [],
  FlameComponentObject(
    name: 'SpriteGroupComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('sprites', 'Map<T, Sprite>?', 'null'),
      FlameComponentField('current', 'T?', 'null'),
      FlameComponentField('autoResize', 'bool?', 'null'),
      FlameComponentField('paint', 'Paint?', 'null'),
      FlameComponentField('super.position', 'dynamic', 'null'),
      FlameComponentField('size', 'Vector2?', 'null'),
      FlameComponentField('super.scale', 'dynamic', 'null'),
      FlameComponentField('super.angle', 'dynamic', 'null'),
      FlameComponentField('super.nativeAngle', 'dynamic', 'null'),
      FlameComponentField('super.anchor', 'dynamic', 'null'),
      FlameComponentField('super.children', 'dynamic', 'null'),
      FlameComponentField('super.priority', 'dynamic', 'null'),
      FlameComponentField('super.key', 'dynamic', 'null')
    ],
    data: {
      "kind": "class",
      "name": "SpriteGroupComponent",
      "typeParameters": [
        {"name": "T"}
      ],
      "extends": "PositionComponent",
      "with": ["HasPaint"],
      "implements": ["SizeProvider"],
      "members": [
        {
          "kind": "constructor",
          "name": "SpriteGroupComponent",
          "description":
              "Creates a component with an empty animation which can be set later\n",
          "parameters": {
            "all": [
              {"name": "sprites", "type": "Map<T, Sprite>?"},
              {"name": "current", "type": "T?"},
              {"name": "autoResize", "type": "bool?"},
              {"name": "paint", "type": "Paint?"},
              {"name": "super.position"},
              {"name": "size", "type": "Vector2?"},
              {"name": "super.scale"},
              {"name": "super.angle"},
              {"name": "super.nativeAngle"},
              {"name": "super.anchor"},
              {"name": "super.children"},
              {"name": "super.priority"},
              {"name": "super.key"}
            ],
            "named": 13
          }
        },
        {"kind": "getter", "name": "sprite", "returns": "Sprite?"},
        {
          "kind": "getter",
          "name": "current",
          "description": "Returns the current group state.\n",
          "returns": "T?"
        },
        {
          "kind": "setter",
          "name": "current",
          "description":
              "The the group state to given state.\n\nWill update [size] if [autoResize] is true.\n",
          "parameters": {
            "all": [
              {"name": "value", "type": "T?"}
            ]
          }
        },
        {
          "kind": "getter",
          "name": "autoResize",
          "description": "Returns current value of auto resize flag.\n",
          "returns": "bool"
        },
        {
          "kind": "getter",
          "name": "sprites",
          "description": "Returns the sprites map.\n",
          "returns": "Map<T, Sprite>?"
        },
        {
          "kind": "setter",
          "name": "sprites",
          "description": "Sets the given [value] as sprites map.\n",
          "parameters": {
            "all": [
              {"name": "value", "type": "Map<T, Sprite>?"}
            ]
          }
        },
        {
          "kind": "setter",
          "name": "autoResize",
          "description":
              "Sets the given value of autoResize flag.\n\nWill update the [size] to fit srcSize of\ncurrent [sprite] if set to  true.\n",
          "parameters": {
            "all": [
              {"name": "value", "type": "bool"}
            ]
          }
        },
        {
          "kind": "method",
          "name": "onMount",
          "returns": "void",
          "annotations": [
            {"name": "@override"},
            {"name": "@mustCallSuper"}
          ]
        },
        {
          "kind": "method",
          "name": "render",
          "parameters": {
            "all": [
              {"name": "canvas", "type": "Canvas"}
            ]
          },
          "returns": "void",
          "annotations": [
            {"name": "@mustCallSuper"},
            {"name": "@override"}
          ]
        }
      ]
    },
  )..components = [],
  FlameComponentObject(
    name: 'SpriteAnimationComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('animation', 'SpriteAnimation?', 'null'),
      FlameComponentField('autoResize', 'bool?', 'null'),
      FlameComponentField('removeOnFinish', 'bool', 'false'),
      FlameComponentField('playing', 'bool', 'true'),
      FlameComponentField('paint', 'Paint?', 'null'),
      FlameComponentField('super.position', 'dynamic', 'null'),
      FlameComponentField('super.size', 'dynamic', 'null'),
      FlameComponentField('super.scale', 'dynamic', 'null'),
      FlameComponentField('super.angle', 'dynamic', 'null'),
      FlameComponentField('super.nativeAngle', 'dynamic', 'null'),
      FlameComponentField('super.anchor', 'dynamic', 'null'),
      FlameComponentField('super.children', 'dynamic', 'null'),
      FlameComponentField('super.priority', 'dynamic', 'null'),
      FlameComponentField('super.key', 'dynamic', 'null'),
      FlameComponentField('image', 'Image', 'null'),
      FlameComponentField('data', 'SpriteAnimationData', 'null'),
      FlameComponentField('autoResize', 'bool?', 'null'),
      FlameComponentField('removeOnFinish', 'bool', 'false'),
      FlameComponentField('playing', 'bool', 'true'),
      FlameComponentField('paint', 'Paint?', 'null'),
      FlameComponentField('position', 'Vector2?', 'null'),
      FlameComponentField('size', 'Vector2?', 'null'),
      FlameComponentField('scale', 'Vector2?', 'null'),
      FlameComponentField('angle', 'double?', 'null'),
      FlameComponentField('anchor', 'Anchor?', 'null'),
      FlameComponentField('priority', 'int?', 'null'),
      FlameComponentField('key', 'ComponentKey?', 'null')
    ],
    data: {
      "kind": "class",
      "name": "SpriteAnimationComponent",
      "extends": "PositionComponent",
      "with": ["HasPaint"],
      "implements": ["SizeProvider"],
      "members": [
        {
          "kind": "getter",
          "name": "animationTicker",
          "description":
              "Returns the animation ticker for current [animation].\n",
          "returns": "SpriteAnimationTicker?"
        },
        {
          "kind": "field",
          "name": "removeOnFinish",
          "type": "bool",
          "description":
              "If the component should be removed once the animation has finished.\nNeeds the animation to have `loop = false` to ever remove the component,\nsince it will never finish otherwise.\n"
        },
        {
          "kind": "field",
          "name": "playing",
          "type": "bool",
          "description": "Whether the animation is paused or playing.\n"
        },
        {
          "kind": "constructor",
          "name": "SpriteAnimationComponent",
          "description":
              "Creates a component with an empty animation which can be set later\n",
          "parameters": {
            "all": [
              {"name": "animation", "type": "SpriteAnimation?"},
              {"name": "autoResize", "type": "bool?"},
              {"name": "this.removeOnFinish", "default": "false"},
              {"name": "this.playing", "default": "true"},
              {"name": "paint", "type": "Paint?"},
              {"name": "super.position"},
              {"name": "super.size"},
              {"name": "super.scale"},
              {"name": "super.angle"},
              {"name": "super.nativeAngle"},
              {"name": "super.anchor"},
              {"name": "super.children"},
              {"name": "super.priority"},
              {"name": "super.key"}
            ],
            "named": 14
          }
        },
        {
          "kind": "constructor",
          "name": "SpriteAnimationComponent.fromFrameData",
          "description":
              "Creates a SpriteAnimationComponent from a [size], an [image] and [data].\nCheck [SpriteAnimationData] for more info on the available options.\n\nOptionally [removeOnFinish] can be set to true to have this component be\nauto removed from the FlameGame when the animation is finished.\n",
          "parameters": {
            "all": [
              {"name": "image", "type": "Image"},
              {"name": "data", "type": "SpriteAnimationData"},
              {"name": "autoResize", "type": "bool?"},
              {"name": "removeOnFinish", "type": "bool", "default": "false"},
              {"name": "playing", "type": "bool", "default": "true"},
              {"name": "paint", "type": "Paint?"},
              {"name": "position", "type": "Vector2?"},
              {"name": "size", "type": "Vector2?"},
              {"name": "scale", "type": "Vector2?"},
              {"name": "angle", "type": "double?"},
              {"name": "anchor", "type": "Anchor?"},
              {"name": "priority", "type": "int?"},
              {"name": "key", "type": "ComponentKey?"}
            ],
            "named": 11
          }
        },
        {
          "kind": "getter",
          "name": "autoResize",
          "description": "Returns current value of auto resize flag.\n",
          "returns": "bool"
        },
        {
          "kind": "setter",
          "name": "autoResize",
          "description":
              "Sets the given value of autoResize flag. Will update the [size]\nto fit srcSize of current sprite if set to  true.\n",
          "parameters": {
            "all": [
              {"name": "value", "type": "bool"}
            ]
          }
        },
        {
          "kind": "getter",
          "name": "animation",
          "description": "Returns the current [SpriteAnimation].\n",
          "returns": "SpriteAnimation?"
        },
        {
          "kind": "setter",
          "name": "animation",
          "description": "Sets the given [value] as current [animation].\n",
          "parameters": {
            "all": [
              {"name": "value", "type": "SpriteAnimation?"}
            ]
          }
        },
        {
          "kind": "method",
          "name": "render",
          "parameters": {
            "all": [
              {"name": "canvas", "type": "Canvas"}
            ]
          },
          "returns": "void",
          "annotations": [
            {"name": "@mustCallSuper"},
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "update",
          "parameters": {
            "all": [
              {"name": "dt", "type": "double"}
            ]
          },
          "returns": "void",
          "annotations": [
            {"name": "@mustCallSuper"},
            {"name": "@override"}
          ]
        }
      ]
    },
  )..components = [],
  FlameComponentObject(
    name: 'IsometricTileMapComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('tileset', 'SpriteSheet', 'null'),
      FlameComponentField('matrix', 'List<List<int>>', 'null'),
      FlameComponentField('destTileSize', 'Vector2?', 'null'),
      FlameComponentField('tileHeight', 'double?', 'null'),
      FlameComponentField('super.position', 'dynamic', 'null'),
      FlameComponentField('super.size', 'dynamic', 'null'),
      FlameComponentField('super.scale', 'dynamic', 'null'),
      FlameComponentField('super.angle', 'dynamic', 'null'),
      FlameComponentField('super.anchor', 'dynamic', 'null'),
      FlameComponentField('super.children', 'dynamic', 'null'),
      FlameComponentField('super.priority', 'dynamic', 'null'),
      FlameComponentField('super.key', 'dynamic', 'null')
    ],
    data: {
      "kind": "class",
      "name": "IsometricTileMapComponent",
      "extends": "PositionComponent",
      "members": [
        {
          "kind": "field",
          "name": "tileset",
          "type": "SpriteSheet",
          "description":
              "This is the tileset that will be used to render this map.\n"
        },
        {
          "kind": "field",
          "name": "matrix",
          "type": "List<List<int>>",
          "description":
              "The positions of each block will be placed respecting this matrix.\n"
        },
        {
          "kind": "field",
          "name": "destTileSize",
          "type": "Vector2?",
          "description":
              "Optionally provide a new tile size to render it scaled.\n"
        },
        {
          "kind": "field",
          "name": "tileHeight",
          "type": "double?",
          "description":
              "This is the vertical height of each block in the tile set.\n\nNote: this must be measured in the destination space.\n"
        },
        {
          "kind": "constructor",
          "name": "IsometricTileMapComponent",
          "parameters": {
            "all": [
              {"name": "this.tileset"},
              {"name": "this.matrix"},
              {"name": "this.destTileSize"},
              {"name": "this.tileHeight"},
              {"name": "super.position"},
              {"name": "super.size"},
              {"name": "super.scale"},
              {"name": "super.angle"},
              {"name": "super.anchor"},
              {"name": "super.children"},
              {"name": "super.priority"},
              {"name": "super.key"}
            ],
            "named": 10
          }
        },
        {
          "kind": "getter",
          "name": "effectiveTileSize",
          "description":
              "This is the size the tiles will be drawn (either original or overwritten).\n",
          "returns": "Vector2"
        },
        {
          "kind": "getter",
          "name": "scalingFactor",
          "description": "The current scaling factor for the isometric view.\n",
          "returns": "double"
        },
        {
          "kind": "getter",
          "name": "effectiveTileHeight",
          "description":
              "This is the vertical height of each block; by default it's half the\ntile size.\n",
          "returns": "double"
        },
        {
          "kind": "method",
          "name": "render",
          "parameters": {
            "all": [
              {"name": "canvas", "type": "Canvas"}
            ]
          },
          "returns": "void",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "getBlockRenderPosition",
          "description":
              "Get the position in which a block is rendered in, in the isometric space.\n\nThis does not include the (x,y) PositionComponent offset!\nThis assumes the tile sprite as a rectangular tile.\nThis is the opposite of [getBlockRenderedAt].\n",
          "parameters": {
            "all": [
              {"name": "block", "type": "Block"}
            ]
          },
          "returns": "Vector2"
        },
        {
          "kind": "method",
          "name": "getBlockRenderPositionInts",
          "description":
              "Same as getBlockRenderPosition but the arguments are exploded as integers.\n",
          "parameters": {
            "all": [
              {"name": "i", "type": "int"},
              {"name": "j", "type": "int"}
            ]
          },
          "returns": "Vector2"
        },
        {
          "kind": "method",
          "name": "getBlockCenterPosition",
          "description":
              "Get the position of the center of the surface of the isometric tile in\nthe cartesian coordinate space.\n\nThis is the opposite of [getBlock].\n",
          "parameters": {
            "all": [
              {"name": "block", "type": "Block"}
            ]
          },
          "returns": "Vector2"
        },
        {
          "kind": "method",
          "name": "isoToCart",
          "description":
              "Converts a coordinate from the isometric space to the cartesian space.\n",
          "parameters": {
            "all": [
              {"name": "p", "type": "Vector2"}
            ]
          },
          "returns": "Vector2"
        },
        {
          "kind": "method",
          "name": "cartToIso",
          "description":
              "Converts a coordinate from the cartesian space to the isometric space.\n",
          "parameters": {
            "all": [
              {"name": "p", "type": "Vector2"}
            ]
          },
          "returns": "Vector2"
        },
        {
          "kind": "method",
          "name": "getBlock",
          "description":
              "Get which block's surface is at isometric position [p].\n\nThis can be used to handle clicks or hovers.\nThis is the opposite of [getBlockCenterPosition].\n",
          "parameters": {
            "all": [
              {"name": "p", "type": "Vector2"}
            ]
          },
          "returns": "Block"
        },
        {
          "kind": "method",
          "name": "getBlockRenderedAt",
          "description":
              "Get which block should be rendered on position [p].\n\nThis is the opposite of [getBlockRenderPosition].\n",
          "parameters": {
            "all": [
              {"name": "p", "type": "Vector2"}
            ]
          },
          "returns": "Block"
        },
        {
          "kind": "method",
          "name": "setBlockValue",
          "description": "Sets the block value into the matrix.\n",
          "parameters": {
            "all": [
              {"name": "pos", "type": "Block"},
              {"name": "block", "type": "int"}
            ]
          },
          "returns": "void"
        },
        {
          "kind": "method",
          "name": "blockValue",
          "description": "Gets the block value from the matrix.\n",
          "parameters": {
            "all": [
              {"name": "pos", "type": "Block"}
            ]
          },
          "returns": "int"
        },
        {
          "kind": "method",
          "name": "containsBlock",
          "description":
              "Return whether the matrix contains a block in its bounds.\n",
          "parameters": {
            "all": [
              {"name": "block", "type": "Block"}
            ]
          },
          "returns": "bool"
        }
      ]
    },
  )..components = [],
  FlameComponentObject(
    name: 'ParallaxComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('parallax', 'Parallax?', 'null'),
      FlameComponentField('super.position', 'dynamic', 'null'),
      FlameComponentField('size', 'Vector2?', 'null'),
      FlameComponentField('super.scale', 'dynamic', 'null'),
      FlameComponentField('super.angle', 'dynamic', 'null'),
      FlameComponentField('super.anchor', 'dynamic', 'null'),
      FlameComponentField('super.children', 'dynamic', 'null'),
      FlameComponentField('super.priority', 'dynamic', 'null'),
      FlameComponentField('super.key', 'dynamic', 'null')
    ],
    data: {
      "kind": "class",
      "name": "ParallaxComponent",
      "typeParameters": [
        {"name": "T", "extends": "FlameGame"}
      ],
      "extends": "PositionComponent",
      "with": ["HasGameReference<T>"],
      "members": [
        {"kind": "field", "name": "isFullscreen", "type": "bool"},
        {"kind": "getter", "name": "parallax", "returns": "Parallax?"},
        {
          "kind": "setter",
          "name": "parallax",
          "parameters": {
            "all": [
              {"name": "p", "type": "Parallax?"}
            ]
          }
        },
        {
          "kind": "constructor",
          "name": "ParallaxComponent",
          "description":
              "Creates a component with an empty parallax which can be set later.\n",
          "parameters": {
            "all": [
              {"name": "parallax", "type": "Parallax?"},
              {"name": "super.position"},
              {"name": "size", "type": "Vector2?"},
              {"name": "super.scale"},
              {"name": "super.angle"},
              {"name": "super.anchor"},
              {"name": "super.children"},
              {"name": "super.priority"},
              {"name": "super.key"}
            ],
            "named": 9
          }
        },
        {
          "kind": "method",
          "name": "onGameResize",
          "parameters": {
            "all": [
              {"name": "size", "type": "Vector2"}
            ]
          },
          "returns": "void",
          "annotations": [
            {"name": "@mustCallSuper"},
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "onMount",
          "returns": "void",
          "annotations": [
            {"name": "@mustCallSuper"},
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "update",
          "parameters": {
            "all": [
              {"name": "dt", "type": "double"}
            ]
          },
          "returns": "void",
          "annotations": [
            {"name": "@mustCallSuper"},
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "render",
          "parameters": {
            "all": [
              {"name": "canvas", "type": "Canvas"}
            ]
          },
          "returns": "void",
          "annotations": [
            {"name": "@mustCallSuper"},
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "load",
          "description":
              "Note that this method only should be used if all of your layers should\nhave the same layer arguments (how the images should be repeated, aligned\nand filled), otherwise load the [ParallaxLayer]s individually and use the\nnormal constructor.\n\n[load] takes a list of [ParallaxData] of all the images and a size that\nyou want to use in the parallax.\n\nOptionally arguments for the [baseVelocity] and [velocityMultiplierDelta]\ncan be passed in, [baseVelocity] defines what the base velocity of the\nlayers should be and [velocityMultiplierDelta] defines how the velocity\nshould change the closer the layer is (`velocityMultiplierDelta ^ n`,\nwhere `n` is the layer index).\nArguments for how all the images should repeat ([repeat]),\nwhich edge it should align with ([alignment]), which axis it should fill\nthe image on ([fill]) and [images] which is the image cache that should be\nused can also be passed in.\n\nIf no image cache is set, the global flame cache is used.\n",
          "parameters": {
            "all": [
              {"name": "dataList", "type": "Iterable<ParallaxData>"},
              {"name": "baseVelocity", "type": "Vector2?"},
              {"name": "velocityMultiplierDelta", "type": "Vector2?"},
              {
                "name": "repeat",
                "type": "ImageRepeat",
                "default": "ImageRepeat.repeatX"
              },
              {
                "name": "alignment",
                "type": "Alignment",
                "default": "Alignment.bottomLeft"
              },
              {
                "name": "fill",
                "type": "LayerFill",
                "default": "LayerFill.height"
              },
              {"name": "images", "type": "Images?"},
              {"name": "position", "type": "Vector2?"},
              {"name": "size", "type": "Vector2?"},
              {"name": "scale", "type": "Vector2?"},
              {"name": "angle", "type": "double?"},
              {"name": "anchor", "type": "Anchor?"},
              {"name": "priority", "type": "int?"},
              {"name": "filterQuality", "type": "FilterQuality?"},
              {"name": "key", "type": "ComponentKey?"}
            ],
            "named": 14
          },
          "returns": "Future<ParallaxComponent>",
          "static": true
        }
      ]
    },
  )..components = [],
  FlameComponentObject(
    name: 'SpriteAnimationGroupComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('animations', 'Map<T, SpriteAnimation>?', 'null'),
      FlameComponentField('current', 'T?', 'null'),
      FlameComponentField('autoResize', 'bool?', 'null'),
      FlameComponentField('playing', 'bool', 'true'),
      FlameComponentField('removeOnFinish', 'Map<T, bool>', 'const {}'),
      FlameComponentField('paint', 'Paint?', 'null'),
      FlameComponentField('super.position', 'dynamic', 'null'),
      FlameComponentField('super.size', 'dynamic', 'null'),
      FlameComponentField('super.scale', 'dynamic', 'null'),
      FlameComponentField('super.angle', 'dynamic', 'null'),
      FlameComponentField('super.nativeAngle', 'dynamic', 'null'),
      FlameComponentField('super.anchor', 'dynamic', 'null'),
      FlameComponentField('super.children', 'dynamic', 'null'),
      FlameComponentField('super.priority', 'dynamic', 'null'),
      FlameComponentField('super.key', 'dynamic', 'null'),
      FlameComponentField('image', 'Image', 'null'),
      FlameComponentField('data', 'Map<T, SpriteAnimationData>', 'null'),
      FlameComponentField('current', 'T?', 'null'),
      FlameComponentField('autoResize', 'bool?', 'null'),
      FlameComponentField('playing', 'bool', 'true'),
      FlameComponentField('removeOnFinish', 'Map<T, bool>', 'const {}'),
      FlameComponentField('paint', 'Paint?', 'null'),
      FlameComponentField('position', 'Vector2?', 'null'),
      FlameComponentField('size', 'Vector2?', 'null'),
      FlameComponentField('scale', 'Vector2?', 'null'),
      FlameComponentField('angle', 'double?', 'null'),
      FlameComponentField('anchor', 'Anchor?', 'null'),
      FlameComponentField('priority', 'int?', 'null'),
      FlameComponentField('key', 'ComponentKey?', 'null')
    ],
    data: {
      "kind": "class",
      "name": "SpriteAnimationGroupComponent",
      "typeParameters": [
        {"name": "T"}
      ],
      "extends": "PositionComponent",
      "with": ["HasPaint"],
      "implements": ["SizeProvider"],
      "members": [
        {
          "kind": "field",
          "name": "removeOnFinish",
          "type": "Map<T, bool>",
          "description":
              "Map with the mapping each state to the flag removeOnFinish\n",
          "final": true
        },
        {
          "kind": "field",
          "name": "playing",
          "type": "bool",
          "description": "Whether the animation is paused or playing.\n"
        },
        {
          "kind": "constructor",
          "name": "SpriteAnimationGroupComponent",
          "description":
              "Creates a component with an empty animation which can be set later\n",
          "parameters": {
            "all": [
              {"name": "animations", "type": "Map<T, SpriteAnimation>?"},
              {"name": "current", "type": "T?"},
              {"name": "autoResize", "type": "bool?"},
              {"name": "this.playing", "default": "true"},
              {"name": "this.removeOnFinish", "default": "const {}"},
              {"name": "paint", "type": "Paint?"},
              {"name": "super.position"},
              {"name": "super.size"},
              {"name": "super.scale"},
              {"name": "super.angle"},
              {"name": "super.nativeAngle"},
              {"name": "super.anchor"},
              {"name": "super.children"},
              {"name": "super.priority"},
              {"name": "super.key"}
            ],
            "named": 15
          }
        },
        {
          "kind": "constructor",
          "name": "SpriteAnimationGroupComponent.fromFrameData",
          "description":
              "Creates a SpriteAnimationGroupComponent from a [size], an [image] and\n[data].\nCheck [SpriteAnimationData] for more info on the available options.\n\nOptionally [removeOnFinish] can be mapped to true to have this component\nbe auto removed from the FlameGame when the animation is finished.\n",
          "parameters": {
            "all": [
              {"name": "image", "type": "Image"},
              {"name": "data", "type": "Map<T, SpriteAnimationData>"},
              {"name": "current", "type": "T?"},
              {"name": "autoResize", "type": "bool?"},
              {"name": "playing", "type": "bool", "default": "true"},
              {
                "name": "removeOnFinish",
                "type": "Map<T, bool>",
                "default": "const {}"
              },
              {"name": "paint", "type": "Paint?"},
              {"name": "position", "type": "Vector2?"},
              {"name": "size", "type": "Vector2?"},
              {"name": "scale", "type": "Vector2?"},
              {"name": "angle", "type": "double?"},
              {"name": "anchor", "type": "Anchor?"},
              {"name": "priority", "type": "int?"},
              {"name": "key", "type": "ComponentKey?"}
            ],
            "named": 12
          }
        },
        {"kind": "getter", "name": "animation", "returns": "SpriteAnimation?"},
        {
          "kind": "getter",
          "name": "animationTicker",
          "returns": "SpriteAnimationTicker?"
        },
        {
          "kind": "getter",
          "name": "current",
          "description": "Returns the current group state.\n",
          "returns": "T?"
        },
        {
          "kind": "setter",
          "name": "current",
          "description":
              "The the group state to given state.\n\nWill update [size] if [autoResize] is true.\n",
          "parameters": {
            "all": [
              {"name": "value", "type": "T?"}
            ]
          }
        },
        {
          "kind": "getter",
          "name": "animations",
          "description":
              "Returns the map of animation state and their corresponding animations.\n",
          "returns": "Map<T, SpriteAnimation>?"
        },
        {
          "kind": "setter",
          "name": "animations",
          "description": "Sets the given [value] as new animation state map.\n",
          "parameters": {
            "all": [
              {"name": "value", "type": "Map<T, SpriteAnimation>?"}
            ]
          }
        },
        {
          "kind": "getter",
          "name": "animationTickers",
          "description":
              "Returns a map containing [SpriteAnimationTicker] for each state.\n",
          "returns": "Map<T, SpriteAnimationTicker>?"
        },
        {
          "kind": "getter",
          "name": "autoResize",
          "description": "Returns current value of auto resize flag.\n",
          "returns": "bool"
        },
        {
          "kind": "setter",
          "name": "autoResize",
          "description":
              "Sets the given value of autoResize flag.\n\nWill update the [size] to fit srcSize of current animation sprite if set\nto  true.\n",
          "parameters": {
            "all": [
              {"name": "value", "type": "bool"}
            ]
          }
        },
        {
          "kind": "method",
          "name": "render",
          "parameters": {
            "all": [
              {"name": "canvas", "type": "Canvas"}
            ]
          },
          "returns": "void",
          "annotations": [
            {"name": "@mustCallSuper"},
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "update",
          "parameters": {
            "all": [
              {"name": "dt", "type": "double"}
            ]
          },
          "returns": "void",
          "annotations": [
            {"name": "@mustCallSuper"},
            {"name": "@override"}
          ]
        }
      ]
    },
  )..components = [],
  FlameComponentObject(
    name: 'SpriteComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('sprite', 'Sprite?', 'null'),
      FlameComponentField('autoResize', 'bool?', 'null'),
      FlameComponentField('paint', 'Paint?', 'null'),
      FlameComponentField('super.position', 'dynamic', 'null'),
      FlameComponentField('size', 'Vector2?', 'null'),
      FlameComponentField('super.scale', 'dynamic', 'null'),
      FlameComponentField('super.angle', 'dynamic', 'null'),
      FlameComponentField('super.nativeAngle', 'dynamic', 'null'),
      FlameComponentField('super.anchor', 'dynamic', 'null'),
      FlameComponentField('super.children', 'dynamic', 'null'),
      FlameComponentField('super.priority', 'dynamic', 'null'),
      FlameComponentField('super.key', 'dynamic', 'null'),
      FlameComponentField('image', 'Image', 'null'),
      FlameComponentField('srcPosition', 'Vector2?', 'null'),
      FlameComponentField('srcSize', 'Vector2?', 'null'),
      FlameComponentField('autoResize', 'bool?', 'null'),
      FlameComponentField('paint', 'Paint?', 'null'),
      FlameComponentField('position', 'Vector2?', 'null'),
      FlameComponentField('size', 'Vector2?', 'null'),
      FlameComponentField('scale', 'Vector2?', 'null'),
      FlameComponentField('angle', 'double?', 'null'),
      FlameComponentField('anchor', 'Anchor?', 'null'),
      FlameComponentField('children', 'Iterable<Component>?', 'null'),
      FlameComponentField('priority', 'int?', 'null'),
      FlameComponentField('key', 'ComponentKey?', 'null')
    ],
    data: {
      "kind": "class",
      "name": "SpriteComponent",
      "extends": "PositionComponent",
      "with": ["HasPaint"],
      "implements": ["SizeProvider"],
      "members": [
        {
          "kind": "constructor",
          "name": "SpriteComponent",
          "description":
              "Creates a component with an empty sprite which can be set later\n",
          "parameters": {
            "all": [
              {"name": "sprite", "type": "Sprite?"},
              {"name": "autoResize", "type": "bool?"},
              {"name": "paint", "type": "Paint?"},
              {"name": "super.position"},
              {"name": "size", "type": "Vector2?"},
              {"name": "super.scale"},
              {"name": "super.angle"},
              {"name": "super.nativeAngle"},
              {"name": "super.anchor"},
              {"name": "super.children"},
              {"name": "super.priority"},
              {"name": "super.key"}
            ],
            "named": 12
          }
        },
        {
          "kind": "constructor",
          "name": "SpriteComponent.fromImage",
          "parameters": {
            "all": [
              {"name": "image", "type": "Image"},
              {"name": "srcPosition", "type": "Vector2?"},
              {"name": "srcSize", "type": "Vector2?"},
              {"name": "autoResize", "type": "bool?"},
              {"name": "paint", "type": "Paint?"},
              {"name": "position", "type": "Vector2?"},
              {"name": "size", "type": "Vector2?"},
              {"name": "scale", "type": "Vector2?"},
              {"name": "angle", "type": "double?"},
              {"name": "anchor", "type": "Anchor?"},
              {"name": "children", "type": "Iterable<Component>?"},
              {"name": "priority", "type": "int?"},
              {"name": "key", "type": "ComponentKey?"}
            ],
            "named": 12
          }
        },
        {
          "kind": "getter",
          "name": "autoResize",
          "description": "Returns current value of auto resize flag.\n",
          "returns": "bool"
        },
        {
          "kind": "setter",
          "name": "autoResize",
          "description":
              "Sets the given value of autoResize flag. Will update the [size]\nto fit srcSize of [sprite] if set to  true.\n",
          "parameters": {
            "all": [
              {"name": "value", "type": "bool"}
            ]
          }
        },
        {
          "kind": "getter",
          "name": "sprite",
          "description":
              "Returns the current sprite rendered by this component.\n",
          "returns": "Sprite?"
        },
        {
          "kind": "setter",
          "name": "sprite",
          "description":
              "Sets the given sprite as the new [sprite] of this component.\nWill update the size if [autoResize] is set to true.\n",
          "parameters": {
            "all": [
              {"name": "value", "type": "Sprite?"}
            ]
          }
        },
        {
          "kind": "method",
          "name": "onMount",
          "returns": "void",
          "annotations": [
            {"name": "@override"},
            {"name": "@mustCallSuper"}
          ]
        },
        {
          "kind": "method",
          "name": "render",
          "parameters": {
            "all": [
              {"name": "canvas", "type": "Canvas"}
            ]
          },
          "returns": "void",
          "annotations": [
            {"name": "@mustCallSuper"},
            {"name": "@override"}
          ]
        }
      ]
    },
  )..components = [],
  FlameComponentObject(
    name: 'CircleComponent',
    type: 'ShapeComponent',
    parameters: [
      FlameComponentField('radius', 'double?', 'null'),
      FlameComponentField('super.position', 'dynamic', 'null'),
      FlameComponentField('super.scale', 'dynamic', 'null'),
      FlameComponentField('super.angle', 'dynamic', 'null'),
      FlameComponentField('super.anchor', 'dynamic', 'null'),
      FlameComponentField('super.children', 'dynamic', 'null'),
      FlameComponentField('super.priority', 'dynamic', 'null'),
      FlameComponentField('super.paint', 'dynamic', 'null'),
      FlameComponentField('super.paintLayers', 'dynamic', 'null'),
      FlameComponentField('relation', 'double', 'null'),
      FlameComponentField('parentSize', 'Vector2', 'null'),
      FlameComponentField('super.position', 'dynamic', 'null'),
      FlameComponentField('super.scale', 'dynamic', 'null'),
      FlameComponentField('super.angle', 'dynamic', 'null'),
      FlameComponentField('super.anchor', 'dynamic', 'null'),
      FlameComponentField('super.paint', 'dynamic', 'null'),
      FlameComponentField('super.paintLayers', 'dynamic', 'null')
    ],
    data: {
      "kind": "class",
      "name": "CircleComponent",
      "extends": "ShapeComponent",
      "implements": ["SizeProvider"],
      "members": [
        {
          "kind": "constructor",
          "name": "CircleComponent",
          "description":
              "With this constructor you can create your [CircleComponent] from a radius\nand a position. It will also calculate the bounding rectangle [size] for\nthe [CircleComponent].\n",
          "parameters": {
            "all": [
              {"name": "radius", "type": "double?"},
              {"name": "super.position"},
              {"name": "super.scale"},
              {"name": "super.angle"},
              {"name": "super.anchor"},
              {"name": "super.children"},
              {"name": "super.priority"},
              {"name": "super.paint"},
              {"name": "super.paintLayers"}
            ],
            "named": 9
          }
        },
        {
          "kind": "constructor",
          "name": "CircleComponent.relative",
          "description":
              "With this constructor you define the [CircleComponent] in relation to the\n[parentSize]. For example having a [relation] of 0.5 would create a circle\nthat fills half of the [parentSize].\n",
          "parameters": {
            "all": [
              {"name": "relation", "type": "double"},
              {"name": "parentSize", "type": "Vector2", "required": true},
              {"name": "super.position"},
              {"name": "super.scale"},
              {"name": "super.angle"},
              {"name": "super.anchor"},
              {"name": "super.paint"},
              {"name": "super.paintLayers"}
            ],
            "named": 7
          }
        },
        {
          "kind": "method",
          "name": "onLoad",
          "returns": "Future<void>",
          "annotations": [
            {"name": "@override"},
            {"name": "@mustCallSuper"}
          ]
        },
        {
          "kind": "getter",
          "name": "radius",
          "description": "Get the radius of the circle before scaling.\n",
          "returns": "double"
        },
        {
          "kind": "setter",
          "name": "radius",
          "description":
              "Set the radius of the circle (and therefore the [size]).\n",
          "parameters": {
            "all": [
              {"name": "value", "type": "double"}
            ]
          }
        },
        {
          "kind": "getter",
          "name": "scaledRadius",
          "description":
              "Get the radius of the circle after it has been sized and scaled.\n",
          "returns": "double"
        },
        {
          "kind": "method",
          "name": "render",
          "parameters": {
            "all": [
              {"name": "canvas", "type": "Canvas"}
            ]
          },
          "returns": "void",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "renderDebugMode",
          "parameters": {
            "all": [
              {"name": "canvas", "type": "Canvas"}
            ]
          },
          "returns": "void",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "containsPoint",
          "description":
              "Checks whether the represented circle contains the [point].\n",
          "parameters": {
            "all": [
              {"name": "point", "type": "Vector2"}
            ]
          },
          "returns": "bool",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "containsLocalPoint",
          "parameters": {
            "all": [
              {"name": "point", "type": "Vector2"}
            ]
          },
          "returns": "bool",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "lineSegmentIntersections",
          "description":
              "Returns the locus of points in which the provided line segment intersects\nthe circle.\n\nThis can be an empty list (if they don't intersect), one point (if the\nline is tangent) or two points (if the line is secant).\nAn edge point of the [lineSegment] that originates on the edge of the\ncircle doesn't count as an intersection.\n",
          "parameters": {
            "all": [
              {"name": "lineSegment", "type": "LineSegment"},
              {
                "name": "epsilon",
                "type": "double",
                "default": "double.minPositive"
              }
            ],
            "named": 1
          },
          "returns": "List<Vector2>"
        }
      ]
    },
  )..components = [],
  FlameComponentObject(
    name: 'PolygonComponent',
    type: 'ShapeComponent',
    parameters: [
      FlameComponentField('_vertices', 'dynamic', 'null'),
      FlameComponentField('super.position', 'dynamic', 'null'),
      FlameComponentField('super.size', 'dynamic', 'null'),
      FlameComponentField('super.scale', 'dynamic', 'null'),
      FlameComponentField('super.angle', 'dynamic', 'null'),
      FlameComponentField('super.anchor', 'dynamic', 'null'),
      FlameComponentField('super.children', 'dynamic', 'null'),
      FlameComponentField('super.priority', 'dynamic', 'null'),
      FlameComponentField('super.paint', 'dynamic', 'null'),
      FlameComponentField('super.paintLayers', 'dynamic', 'null'),
      FlameComponentField('super.key', 'dynamic', 'null'),
      FlameComponentField('shrinkToBounds', 'bool?', 'null'),
      FlameComponentField('relation', 'List<Vector2>', 'null'),
      FlameComponentField('parentSize', 'Vector2', 'null'),
      FlameComponentField('position', 'Vector2?', 'null'),
      FlameComponentField('scale', 'Vector2?', 'null'),
      FlameComponentField('angle', 'double?', 'null'),
      FlameComponentField('anchor', 'Anchor?', 'null'),
      FlameComponentField('priority', 'int?', 'null'),
      FlameComponentField('paint', 'Paint?', 'null'),
      FlameComponentField('paintLayers', 'List<Paint>?', 'null'),
      FlameComponentField('shrinkToBounds', 'bool?', 'null'),
      FlameComponentField('key', 'ComponentKey?', 'null')
    ],
    data: {
      "kind": "class",
      "name": "PolygonComponent",
      "extends": "ShapeComponent",
      "members": [
        {
          "kind": "getter",
          "name": "vertices",
          "returns": "UnmodifiableListView<Vector2>"
        },
        {
          "kind": "field",
          "name": "shrinkToBounds",
          "type": "bool",
          "final": true
        },
        {
          "kind": "field",
          "name": "manuallyPositioned",
          "type": "bool",
          "final": true
        },
        {
          "kind": "constructor",
          "name": "PolygonComponent",
          "description":
              "With this constructor you create your [PolygonComponent] from positions in\nanywhere in the 2d-space. It will automatically calculate the [size] of\nthe Polygon (the bounding box) if no size it given.\nNOTE: Always define your polygon in a counter-clockwise fashion (in the\nscreen coordinate system).\n",
          "parameters": {
            "all": [
              {"name": "this._vertices"},
              {"name": "super.position"},
              {"name": "super.size"},
              {"name": "super.scale"},
              {"name": "super.angle"},
              {"name": "super.anchor"},
              {"name": "super.children"},
              {"name": "super.priority"},
              {"name": "super.paint"},
              {"name": "super.paintLayers"},
              {"name": "super.key"},
              {"name": "shrinkToBounds", "type": "bool?"}
            ],
            "named": 11
          }
        },
        {
          "kind": "constructor",
          "name": "PolygonComponent.relative",
          "description":
              "With this constructor you define the [PolygonComponent] in relation to the\n[parentSize] of the shape.\n\nExample: `[[1.0, 0.0], [0.0, -1.0], [-1.0, 0.0], [0.0, 1.0]]`\nThis will form a diamond shape within the bounding size box.\nNOTE: Always define your shape in a counter-clockwise fashion (in the\nscreen coordinate system).\n",
          "parameters": {
            "all": [
              {"name": "relation", "type": "List<Vector2>"},
              {"name": "parentSize", "type": "Vector2", "required": true},
              {"name": "position", "type": "Vector2?"},
              {"name": "scale", "type": "Vector2?"},
              {"name": "angle", "type": "double?"},
              {"name": "anchor", "type": "Anchor?"},
              {"name": "priority", "type": "int?"},
              {"name": "paint", "type": "Paint?"},
              {"name": "paintLayers", "type": "List<Paint>?"},
              {"name": "shrinkToBounds", "type": "bool?"},
              {"name": "key", "type": "ComponentKey?"}
            ],
            "named": 10
          }
        },
        {
          "kind": "method",
          "name": "refreshVertices",
          "parameters": {
            "all": [
              {
                "name": "newVertices",
                "type": "List<Vector2>",
                "required": true
              },
              {"name": "shrinkToBoundsOverride", "type": "bool?"}
            ],
            "named": 2
          },
          "returns": "void",
          "annotations": [
            {"name": "@protected"}
          ]
        },
        {
          "kind": "method",
          "name": "globalVertices",
          "description":
              "gives back the shape vectors multiplied by the size and scale\n",
          "returns": "List<Vector2>"
        },
        {
          "kind": "method",
          "name": "render",
          "parameters": {
            "all": [
              {"name": "canvas", "type": "Canvas"}
            ]
          },
          "returns": "void",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "renderDebugMode",
          "parameters": {
            "all": [
              {"name": "canvas", "type": "Canvas"}
            ]
          },
          "returns": "void",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "containsPoint",
          "description":
              "Checks whether the polygon contains the [point].\nNote: The polygon needs to be convex for this to work.\n",
          "parameters": {
            "all": [
              {"name": "point", "type": "Vector2"}
            ]
          },
          "returns": "bool",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "containsLocalPoint",
          "parameters": {
            "all": [
              {"name": "point", "type": "Vector2"}
            ]
          },
          "returns": "bool",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "possibleIntersectionVertices",
          "description":
              "Return all vertices as [LineSegment]s that intersect [rect], if [rect]\nis null return all vertices as [LineSegment]s.\n",
          "parameters": {
            "all": [
              {"name": "rect", "type": "Rect?"}
            ]
          },
          "returns": "List<LineSegment>"
        },
        {
          "kind": "method",
          "name": "getEdge",
          "parameters": {
            "all": [
              {"name": "i", "type": "int"},
              {"name": "vertices", "type": "List<Vector2>", "required": true}
            ],
            "named": 1
          },
          "returns": "LineSegment"
        },
        {
          "kind": "method",
          "name": "getVertex",
          "parameters": {
            "all": [
              {"name": "i", "type": "int"},
              {"name": "vertices", "type": "List<Vector2>?"}
            ],
            "named": 1
          },
          "returns": "Vector2"
        }
      ]
    },
  )..components = [],
  FlameComponentObject(
    name: 'TextBoxComponent',
    type: 'TextComponent',
    parameters: [
      FlameComponentField('super.text', 'dynamic', 'null'),
      FlameComponentField('super.textRenderer', 'dynamic', 'null'),
      FlameComponentField('boxConfig', 'TextBoxConfig?', 'null'),
      FlameComponentField('align', 'Anchor?', 'null'),
      FlameComponentField('pixelRatio', 'double?', 'null'),
      FlameComponentField('super.position', 'dynamic', 'null'),
      FlameComponentField('super.size', 'dynamic', 'null'),
      FlameComponentField('super.scale', 'dynamic', 'null'),
      FlameComponentField('super.angle', 'dynamic', 'null'),
      FlameComponentField('super.anchor', 'dynamic', 'null'),
      FlameComponentField('super.children', 'dynamic', 'null'),
      FlameComponentField('super.priority', 'dynamic', 'null'),
      FlameComponentField('super.key', 'dynamic', 'null')
    ],
    data: {
      "kind": "class",
      "name": "TextBoxComponent",
      "typeParameters": [
        {"name": "T", "extends": "TextRenderer"}
      ],
      "extends": "TextComponent",
      "members": [
        {
          "kind": "field",
          "name": "pixelRatio",
          "type": "double",
          "final": true
        },
        {"kind": "getter", "name": "boxConfig", "returns": "TextBoxConfig"},
        {
          "kind": "constructor",
          "name": "TextBoxComponent",
          "parameters": {
            "all": [
              {"name": "super.text"},
              {"name": "super.textRenderer"},
              {"name": "boxConfig", "type": "TextBoxConfig?"},
              {"name": "align", "type": "Anchor?"},
              {"name": "pixelRatio", "type": "double?"},
              {"name": "super.position"},
              {"name": "super.size"},
              {"name": "super.scale"},
              {"name": "super.angle"},
              {"name": "super.anchor"},
              {"name": "super.children"},
              {"name": "super.priority"},
              {"name": "super.key"}
            ],
            "named": 13
          }
        },
        {
          "kind": "field",
          "name": "align",
          "type": "Anchor",
          "description":
              "Alignment of the text within its bounding box.\n\nThis property combines both the horizontal and vertical alignment. For\nexample, setting this property to `Align.center` will make the text\ncentered inside its box. Similarly, `Align.bottomRight` will render the\ntext that's aligned to the right and to the bottom of the box.\n\nCustom alignment anchors are supported too. For example, if this property\nis set to `Anchor(0.1, 0)`, then the text would be positioned such that\nits every line will have 10% of whitespace on the left, and 90% on the\nright. You can use an `AnchorEffect` to make the text gradually transition\nbetween different alignment values.\n"
        },
        {
          "kind": "setter",
          "name": "text",
          "parameters": {
            "all": [
              {"name": "value", "type": "String"}
            ]
          },
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "onLoad",
          "returns": "Future<void>",
          "annotations": [
            {"name": "@override"},
            {"name": "@mustCallSuper"}
          ]
        },
        {
          "kind": "method",
          "name": "onMount",
          "returns": "void",
          "annotations": [
            {"name": "@override"},
            {"name": "@mustCallSuper"}
          ]
        },
        {"kind": "getter", "name": "totalCharTime", "returns": "double"},
        {"kind": "getter", "name": "finished", "returns": "bool"},
        {"kind": "getter", "name": "currentChar", "returns": "int"},
        {"kind": "getter", "name": "currentLine", "returns": "int"},
        {
          "kind": "method",
          "name": "getLineWidth",
          "parameters": {
            "all": [
              {"name": "line", "type": "String"},
              {"name": "charCount", "type": "int"}
            ]
          },
          "returns": "double"
        },
        {
          "kind": "method",
          "name": "render",
          "parameters": {
            "all": [
              {"name": "canvas", "type": "Canvas"}
            ]
          },
          "returns": "void",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "drawBackground",
          "description":
              "Override this method to provide a custom background to the text box.\n",
          "parameters": {
            "all": [
              {"name": "c", "type": "Canvas"}
            ]
          },
          "returns": "void"
        },
        {
          "kind": "field",
          "name": "cachedToRemove",
          "type": "Set<Image>",
          "final": true
        },
        {"kind": "method", "name": "redraw", "returns": "Future<void>"},
        {
          "kind": "method",
          "name": "update",
          "parameters": {
            "all": [
              {"name": "dt", "type": "double"}
            ]
          },
          "returns": "void",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "onRemove",
          "returns": "void",
          "annotations": [
            {"name": "@override"},
            {"name": "@mustCallSuper"}
          ]
        }
      ]
    },
  )..components = [],
  FlameComponentObject(
    name: 'CameraComponent',
    type: 'Component',
    parameters: [
      FlameComponentField('world', 'World?', 'null'),
      FlameComponentField('viewport', 'Viewport?', 'null'),
      FlameComponentField('viewfinder', 'Viewfinder?', 'null'),
      FlameComponentField('backdrop', 'Component?', 'null'),
      FlameComponentField('hudComponents', 'List<Component>?', 'null'),
      FlameComponentField('width', 'double', 'null'),
      FlameComponentField('height', 'double', 'null'),
      FlameComponentField('viewfinder', 'Viewfinder?', 'null'),
      FlameComponentField('world', 'World?', 'null'),
      FlameComponentField('backdrop', 'Component?', 'null'),
      FlameComponentField('hudComponents', 'List<Component>?', 'null')
    ],
    data: {
      "kind": "class",
      "name": "CameraComponent",
      "extends": "Component",
      "members": [
        {
          "kind": "constructor",
          "name": "CameraComponent",
          "parameters": {
            "all": [
              {"name": "this.world"},
              {"name": "viewport", "type": "Viewport?"},
              {"name": "viewfinder", "type": "Viewfinder?"},
              {"name": "backdrop", "type": "Component?"},
              {"name": "hudComponents", "type": "List<Component>?"}
            ],
            "named": 5
          }
        },
        {
          "kind": "constructor",
          "name": "CameraComponent.withFixedResolution",
          "factory": true,
          "description":
              "Create a camera that shows a portion of the game world of fixed size\n[width] x [height].\n\nThe viewport will be centered within the canvas, expanding as much as\npossible on all sides while maintaining the [width]:[height] aspect ratio.\nThe zoom level will be set such in such a way that exactly [width] x\n[height] pixels are visible within the viewport. The viewfinder will be\ninitially set up to show world coordinates (0, 0) at the center of the\nviewport.\n",
          "parameters": {
            "all": [
              {"name": "width", "type": "double", "required": true},
              {"name": "height", "type": "double", "required": true},
              {"name": "viewfinder", "type": "Viewfinder?"},
              {"name": "world", "type": "World?"},
              {"name": "backdrop", "type": "Component?"},
              {"name": "hudComponents", "type": "List<Component>?"}
            ],
            "named": 6
          }
        },
        {
          "kind": "getter",
          "name": "viewport",
          "description":
              "The [viewport] is the \"window\" through which the game world is observed.\n\nImagine that the world is covered with an infinite sheet of paper, but\nthere is a hole in it. That hole is the viewport: through that aperture\nthe world can be observed. The viewport's size is equal to or smaller\nthan the size of the game canvas. If it is smaller, then the viewport's\nposition specifies where exactly it is placed on the canvas.\n",
          "returns": "Viewport"
        },
        {
          "kind": "setter",
          "name": "viewport",
          "parameters": {
            "all": [
              {"name": "newViewport", "type": "Viewport"}
            ]
          }
        },
        {
          "kind": "getter",
          "name": "viewfinder",
          "description":
              "The [viewfinder] controls which part of the world is seen through the\nviewport.\n\nThus, viewfinder's `position` is the world point which is seen at the\ncenter of the viewport. In addition, viewfinder controls the zoom level\n(i.e. how much of the world is seen through the viewport), and,\noptionally, rotation.\n",
          "returns": "Viewfinder"
        },
        {
          "kind": "setter",
          "name": "viewfinder",
          "parameters": {
            "all": [
              {"name": "newViewfinder", "type": "Viewfinder"}
            ]
          }
        },
        {
          "kind": "field",
          "name": "world",
          "type": "World?",
          "description":
              "Special component that is designed to be the root of a game world.\n\nMultiple cameras can observe the same [world] simultaneously, and the\nworld may itself contain cameras that look into other worlds, or even into\nitself.\n\nThe [world] component is generally mounted externally to the camera, and\nthis variable is a mere reference to it.\n"
        },
        {
          "kind": "getter",
          "name": "backdrop",
          "description":
              "The [backdrop] component is rendered statically behind the world.\n\nHere you can add things like the parallax component which should be static\nwhen the camera moves around.\n",
          "returns": "Component"
        },
        {
          "kind": "setter",
          "name": "backdrop",
          "parameters": {
            "all": [
              {"name": "newBackdrop", "type": "Component"}
            ]
          }
        },
        {
          "kind": "getter",
          "name": "visibleWorldRect",
          "description":
              "The axis-aligned bounding rectangle of a [world] region which is currently\nvisible through the viewport.\n\nThis property can be useful in order to determine which components within\nthe game's world are currently visible to the player, and which aren't.\n\nIf the viewport is non-rectangular, or if the world's view is rotated,\nthen the [visibleWorldRect] will be larger than the actual viewing area.\nThus, this property is \"conservative\": everything outside of this rect\nis definitely not visible, while the points inside may or may not be\nvisible.\n\nThis property is cached, and is recalculated whenever the camera moves\nor the viewport is resized. At the same time, it may only be accessed\nafter the camera was fully mounted.\n",
          "returns": "Rect"
        },
        {
          "kind": "method",
          "name": "renderTree",
          "description":
              "Renders the [world] as seen through this camera.\n\nIf the world is not mounted yet, only the viewport and viewfinder elements\nwill be rendered.\n",
          "parameters": {
            "all": [
              {"name": "canvas", "type": "Canvas"}
            ]
          },
          "returns": "void",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "globalToLocal",
          "description":
              "Converts from the global (canvas) coordinate space to\nlocal (camera = viewport + viewfinder).\n\nOpposite of [localToGlobal].\n",
          "parameters": {
            "all": [
              {"name": "point", "type": "Vector2"},
              {"name": "output", "type": "Vector2?"}
            ],
            "named": 1
          },
          "returns": "Vector2"
        },
        {
          "kind": "method",
          "name": "localToGlobal",
          "description":
              "Converts from the local (camera = viewport + viewfinder) coordinate space\nto global (canvas).\n\nOpposite of [globalToLocal].\n",
          "parameters": {
            "all": [
              {"name": "position", "type": "Vector2"},
              {"name": "output", "type": "Vector2?"}
            ],
            "named": 1
          },
          "returns": "Vector2"
        },
        {
          "kind": "method",
          "name": "componentsAtPoint",
          "parameters": {
            "all": [
              {"name": "point", "type": "Vector2"},
              {"name": "nestedPoints", "type": "List<Vector2>?"}
            ],
            "positional": 1
          },
          "returns": "Iterable<Component>",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "getter",
          "name": "currentCamera",
          "description":
              "A camera that currently performs rendering.\n\nThis variable is set to `this` when we begin rendering the world through\nthis particular camera, and reset back to `null` at the end. This variable\nis not set when rendering components that are attached to the viewport.\n",
          "returns": "CameraComponent?",
          "static": true
        },
        {
          "kind": "field",
          "name": "currentCameras",
          "type": "List<CameraComponent>",
          "description": "Stack of all current cameras in the render tree.\n",
          "static": true,
          "final": true
        },
        {
          "kind": "field",
          "name": "maxCamerasDepth",
          "type": "int",
          "description":
              "Maximum number of nested cameras that will be rendered.\n\nThis variable helps prevent infinite recursion when a camera is set to\nlook at the world that contains that camera.\n",
          "static": true
        },
        {
          "kind": "method",
          "name": "follow",
          "description":
              "Makes the [viewfinder] follow the given [target].\n\nThe [target] here can be any read-only [PositionProvider]. For example, a\n[PositionComponent] is the most common choice of target. Alternatively,\nyou can use [PositionProviderImpl] to construct the target dynamically.\n\nThis method adds a [FollowBehavior] to the viewfinder. If there is another\n[FollowBehavior] currently applied to the viewfinder, it will be removed\nfirst.\n\nParameters [maxSpeed], [horizontalOnly] and [verticalOnly] have the same\nmeaning as in the [FollowBehavior.new] constructor.\n\nIf [snap] is true, then the viewfinder's starting position will be set to\nthe target's current location. If [snap] is false, then the viewfinder\nwill move from its current position to the target's position at the given\nspeed.\n",
          "parameters": {
            "all": [
              {"name": "target", "type": "ReadOnlyPositionProvider"},
              {
                "name": "maxSpeed",
                "type": "double",
                "default": "double.infinity"
              },
              {"name": "horizontalOnly", "type": "bool", "default": "false"},
              {"name": "verticalOnly", "type": "bool", "default": "false"},
              {"name": "snap", "type": "bool", "default": "false"}
            ],
            "named": 4
          },
          "returns": "void"
        },
        {
          "kind": "method",
          "name": "stop",
          "description":
              "Removes all movement effects or behaviors from the viewfinder.\n",
          "returns": "void"
        },
        {
          "kind": "method",
          "name": "moveTo",
          "description":
              "Moves the camera towards the specified world [point].\n",
          "parameters": {
            "all": [
              {"name": "point", "type": "Vector2"},
              {"name": "speed", "type": "double", "default": "double.infinity"}
            ],
            "named": 1
          },
          "returns": "void"
        },
        {
          "kind": "method",
          "name": "moveBy",
          "description": "Move the camera by the given [offset].\n",
          "parameters": {
            "all": [
              {"name": "offset", "type": "Vector2"},
              {"name": "speed", "type": "double", "default": "double.infinity"}
            ],
            "named": 1
          },
          "returns": "void"
        },
        {
          "kind": "method",
          "name": "setBounds",
          "description":
              "Sets or clears the world bounds for the camera's viewfinder.\n\nThe bound is a [Shape], given in the world coordinates. The viewfinder's\nposition will be restricted to always remain inside this region. Note that\nif you want the camera to never see the empty space outside of the world's\nrendering area, then you should set up the bounds to be smaller than the\nsize of the world.\n",
          "parameters": {
            "all": [
              {"name": "bounds", "type": "Shape?"}
            ]
          },
          "returns": "void"
        },
        {
          "kind": "method",
          "name": "canSee",
          "description":
              "Returns true if this camera is able to see the [component].\nWill always return false if\n- [world] is null or\n- [world] is not mounted or\n- [component] is not mounted or\n- [componentWorld] is non-null and does not match with [world]\n\nIf [componentWorld] is null, this method does not take into consideration\nthe world to which the given [component] belongs (if any). This means, in\nsuch cases, any component overlapping the [visibleWorldRect] will be\nreported as visible, even if it is not part of the [world] this camera is\ncurrently looking at. This can be changed by passing the the component's\nworld as [componentWorld].\n",
          "parameters": {
            "all": [
              {"name": "component", "type": "PositionComponent"},
              {"name": "componentWorld", "type": "World?"}
            ],
            "named": 1
          },
          "returns": "bool"
        }
      ]
    },
  )..components = [],
  FlameComponentObject(
    name: 'PositionComponent',
    type: 'Component',
    parameters: [
      FlameComponentField('position', 'Vector2?', 'null'),
      FlameComponentField('size', 'Vector2?', 'null'),
      FlameComponentField('scale', 'Vector2?', 'null'),
      FlameComponentField('angle', 'double?', 'null'),
      FlameComponentField('nativeAngle', 'double', '0'),
      FlameComponentField('anchor', 'Anchor?', 'null'),
      FlameComponentField('super.children', 'dynamic', 'null'),
      FlameComponentField('super.priority', 'dynamic', 'null'),
      FlameComponentField('super.key', 'dynamic', 'null')
    ],
    data: {
      "kind": "class",
      "name": "PositionComponent",
      "extends": "Component",
      "implements": [
        "AnchorProvider",
        "AngleProvider",
        "PositionProvider",
        "ScaleProvider",
        "SizeProvider",
        "CoordinateTransform"
      ],
      "members": [
        {
          "kind": "constructor",
          "name": "PositionComponent",
          "parameters": {
            "all": [
              {"name": "position", "type": "Vector2?"},
              {"name": "size", "type": "Vector2?"},
              {"name": "scale", "type": "Vector2?"},
              {"name": "angle", "type": "double?"},
              {"name": "this.nativeAngle", "default": "0"},
              {"name": "anchor", "type": "Anchor?"},
              {"name": "super.children"},
              {"name": "super.priority"},
              {"name": "super.key"}
            ],
            "named": 9
          }
        },
        {
          "kind": "field",
          "name": "transform",
          "type": "Transform2D",
          "final": true
        },
        {
          "kind": "field",
          "name": "nativeAngle",
          "type": "double",
          "description":
              "The angle where this component is looking at when it is in\nthe default state, i.e. when [angle] is equal to zero.\nFor example, a nativeAngle of\n    0 implies up/north direction\n pi/2 implies right/east direction\n   pi implies down/south direction\n-pi/2 implies left/west direction\n"
        },
        {
          "kind": "field",
          "name": "decorator",
          "type": "Decorator",
          "description":
              "The decorator is used to apply visual effects to a component.\n\nBy default, the [PositionComponent] is equipped with a\n[Transform2DDecorator] which makes sure the component is rendered at a\nproper location on the canvas. It is possible to replace this decorator\nwith another one if a different functionality is desired.\n\nA more common use for this field, however, is to apply additional visual\neffects such as tints/shadows/etc using [Decorator.addLast].\n",
          "late": true
        },
        {
          "kind": "getter",
          "name": "transformMatrix",
          "description":
              "The total transformation matrix for the component. This matrix combines\ntranslation, rotation and scale transforms into a single entity. The\nmatrix is cached and gets recalculated only as necessary.\n",
          "returns": "Matrix4"
        },
        {
          "kind": "getter",
          "name": "position",
          "description":
              "The position of this component's anchor on the screen.\n",
          "returns": "NotifyingVector2",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "setter",
          "name": "position",
          "parameters": {
            "all": [
              {"name": "position", "type": "Vector2"}
            ]
          },
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "getter",
          "name": "x",
          "description":
              "X position of this component's anchor on the screen.\n",
          "returns": "double"
        },
        {
          "kind": "setter",
          "name": "x",
          "parameters": {
            "all": [
              {"name": "x", "type": "double"}
            ]
          }
        },
        {
          "kind": "getter",
          "name": "y",
          "description":
              "Y position of this component's anchor on the screen.\n",
          "returns": "double"
        },
        {
          "kind": "setter",
          "name": "y",
          "parameters": {
            "all": [
              {"name": "y", "type": "double"}
            ]
          }
        },
        {
          "kind": "getter",
          "name": "angle",
          "description":
              "Rotation angle (in radians) of the component. The component will be\nrotated around its anchor point in the clockwise direction if the\nangle is positive, or counterclockwise if the angle is negative.\n",
          "returns": "double",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "setter",
          "name": "angle",
          "parameters": {
            "all": [
              {"name": "a", "type": "double"}
            ]
          },
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "getter",
          "name": "scale",
          "description":
              "The scale factor of this component. The scale can be different along\nthe X and Y dimensions. A scale greater than 1 makes the component\nbigger, and less than 1 smaller. The scale can also be negative,\nwhich results in a mirror reflection along the corresponding axis.\n",
          "returns": "NotifyingVector2",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "setter",
          "name": "scale",
          "parameters": {
            "all": [
              {"name": "scale", "type": "Vector2"}
            ]
          },
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "getter",
          "name": "anchor",
          "description":
              "Anchor point for this component. An anchor point describes a point\nwithin the rectangle of size [size]. This point is considered to\nbe the logical \"center\" of the component. This can be visualized\nas the point where Flame \"grabs\" the component. All transforms\noccur around this point: the [position] is where the anchor point\nwill end up after the component is translated; the rotation and\nscaling also happen around this anchor point.\n\nThe [anchor] of a component can be modified during runtime. When\nthis happens, the [position] of the component will remain unchanged,\nwhich means that visually the component will shift on the screen\nso that its new anchor will be at the same screen coordinates as\nthe old anchor was.\n",
          "returns": "Anchor",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "setter",
          "name": "anchor",
          "parameters": {
            "all": [
              {"name": "anchor", "type": "Anchor"}
            ]
          },
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "getter",
          "name": "size",
          "description":
              "The logical size of the component. The game assumes that this is the\napproximate size of the object that will be drawn on the screen.\nThis size will therefore be used for collision detection and tap\nhandling.\n\nThis property can be reassigned at runtime, although this is not\nrecommended. Instead, in order to make the [PositionComponent] larger\nor smaller, change its [scale].\n",
          "returns": "NotifyingVector2",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "setter",
          "name": "size",
          "parameters": {
            "all": [
              {"name": "size", "type": "Vector2"}
            ]
          },
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "getter",
          "name": "width",
          "description":
              "The width of the component in local coordinates. Note that the object\nmay visually appear larger or smaller due to application of [scale].\n",
          "returns": "double"
        },
        {
          "kind": "setter",
          "name": "width",
          "parameters": {
            "all": [
              {"name": "w", "type": "double"}
            ]
          }
        },
        {
          "kind": "getter",
          "name": "height",
          "description":
              "The height of the component in local coordinates. Note that the object\nmay visually appear larger or smaller due to application of [scale].\n",
          "returns": "double"
        },
        {
          "kind": "setter",
          "name": "height",
          "parameters": {
            "all": [
              {"name": "h", "type": "double"}
            ]
          }
        },
        {
          "kind": "getter",
          "name": "scaledSize",
          "description":
              "The \"physical\" size of the component. This is the size of the\ncomponent as seen from the parent's perspective, and it is equal to\n[size] * [scale]. This is a computed property and cannot be\nmodified by the user.\n",
          "returns": "Vector2"
        },
        {
          "kind": "getter",
          "name": "absoluteScaledSize",
          "description":
              "The resulting size after all the ancestors and the components own scale\nhas been applied.\n",
          "returns": "Vector2"
        },
        {
          "kind": "getter",
          "name": "absoluteAngle",
          "description":
              "The resulting angle after all the ancestors and the components own angle\nhas been applied.\n",
          "returns": "double"
        },
        {
          "kind": "getter",
          "name": "absoluteScale",
          "description":
              "The resulting scale after all the ancestors and the components own scale\nhas been applied.\n",
          "returns": "Vector2"
        },
        {
          "kind": "method",
          "name": "distance",
          "description":
              "Measure the distance (in parent's coordinate space) between this\ncomponent's anchor and the [other] component's anchor.\n",
          "parameters": {
            "all": [
              {"name": "other", "type": "PositionComponent"}
            ]
          },
          "returns": "double"
        },
        {
          "kind": "method",
          "name": "containsLocalPoint",
          "description":
              "Test whether the `point` (given in local coordinates) lies within this\ncomponent. The top and the left borders of the component are inclusive,\nwhile the bottom and the right borders are exclusive.\n",
          "parameters": {
            "all": [
              {"name": "point", "type": "Vector2"}
            ]
          },
          "returns": "bool",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "containsPoint",
          "description":
              "Test whether the `point` (given in global coordinates) lies within this\ncomponent. The top and the left borders of the component are inclusive,\nwhile the bottom and the right borders are exclusive.\n",
          "parameters": {
            "all": [
              {"name": "point", "type": "Vector2"}
            ]
          },
          "returns": "bool",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "parentToLocal",
          "parameters": {
            "all": [
              {"name": "point", "type": "Vector2"}
            ]
          },
          "returns": "Vector2",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "localToParent",
          "parameters": {
            "all": [
              {"name": "point", "type": "Vector2"}
            ]
          },
          "returns": "Vector2",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "positionOf",
          "description":
              "Convert local coordinates of a point [point] inside the component\ninto the parent's coordinate space.\n",
          "parameters": {
            "all": [
              {"name": "point", "type": "Vector2"}
            ]
          },
          "returns": "Vector2"
        },
        {
          "kind": "method",
          "name": "positionOfAnchor",
          "description":
              "Similar to [positionOf()], but applies to any anchor point within\nthe component.\n",
          "parameters": {
            "all": [
              {"name": "anchor", "type": "Anchor"}
            ]
          },
          "returns": "Vector2"
        },
        {
          "kind": "method",
          "name": "absolutePositionOf",
          "description":
              "Convert local coordinates of a point [point] inside the component\ninto the global (world) coordinate space.\n",
          "parameters": {
            "all": [
              {"name": "point", "type": "Vector2"}
            ]
          },
          "returns": "Vector2"
        },
        {
          "kind": "method",
          "name": "absolutePositionOfAnchor",
          "description":
              "Similar to [absolutePositionOf()], but applies to any anchor\npoint within the component.\n",
          "parameters": {
            "all": [
              {"name": "anchor", "type": "Anchor"}
            ]
          },
          "returns": "Vector2"
        },
        {
          "kind": "method",
          "name": "toLocal",
          "description":
              "Transform [point] from the parent's coordinate space into the local\ncoordinates. This function is the inverse of [positionOf()].\n",
          "parameters": {
            "all": [
              {"name": "point", "type": "Vector2"}
            ]
          },
          "returns": "Vector2"
        },
        {
          "kind": "method",
          "name": "absoluteToLocal",
          "description":
              "Transform [point] from the global (world) coordinate space into the\nlocal coordinates. This function is the inverse of\n[absolutePositionOf()].\n\nThis can be used, for example, to detect whether a specific point\non the screen lies within this [PositionComponent], and where\nexactly it hits.\n",
          "parameters": {
            "all": [
              {"name": "point", "type": "Vector2"}
            ]
          },
          "returns": "Vector2"
        },
        {
          "kind": "getter",
          "name": "topLeftPosition",
          "description":
              "The top-left corner's position in the parent's coordinates.\n",
          "returns": "Vector2"
        },
        {
          "kind": "setter",
          "name": "topLeftPosition",
          "parameters": {
            "all": [
              {"name": "point", "type": "Vector2"}
            ]
          }
        },
        {
          "kind": "getter",
          "name": "center",
          "description":
              "The position of the center of the component's bounding rectangle\nin the parent's coordinates.\n",
          "returns": "Vector2"
        },
        {
          "kind": "setter",
          "name": "center",
          "parameters": {
            "all": [
              {"name": "point", "type": "Vector2"}
            ]
          }
        },
        {
          "kind": "getter",
          "name": "absolutePosition",
          "description":
              "The [anchor]'s position in absolute (world) coordinates.\n",
          "returns": "Vector2"
        },
        {
          "kind": "getter",
          "name": "absoluteTopLeftPosition",
          "description":
              "The absolute top left position regardless of whether it is a child or not.\n",
          "returns": "Vector2"
        },
        {
          "kind": "getter",
          "name": "absoluteCenter",
          "description": "The absolute center of the component.\n",
          "returns": "Vector2"
        },
        {
          "kind": "method",
          "name": "angleTo",
          "description":
              "Returns the angle formed by component's orientation vector and a vector\nstarting at component's absolute position and ending at [target]. This\nangle is measured in clockwise direction. [target] should be in absolute/world\ncoordinate system.\n\nUses [nativeAngle] to decide the orientation direction of the component.\nSee [lookAt] to make the component instantly rotate towards target.\n\nNote: If target coincides with the current component, then it is treated\nas being north.\n",
          "parameters": {
            "all": [
              {"name": "target", "type": "Vector2"}
            ]
          },
          "returns": "double"
        },
        {
          "kind": "method",
          "name": "lookAt",
          "description":
              "Rotates/snaps the component to look at the [target].\n\nThis method sets the [angle] so that the component's orientation\nvector (as determined by the [nativeAngle]) is pointing at the target.\n[target] should to be in absolute/world coordinate system.\n\nSee also: [angleTo]\n",
          "parameters": {
            "all": [
              {"name": "target", "type": "Vector2"}
            ]
          },
          "returns": "void"
        },
        {
          "kind": "method",
          "name": "flipHorizontally",
          "description":
              "Flip the component horizontally around its anchor point.\n",
          "returns": "void"
        },
        {
          "kind": "method",
          "name": "flipVertically",
          "description":
              "Flip the component vertically around its anchor point.\n",
          "returns": "void"
        },
        {
          "kind": "method",
          "name": "flipHorizontallyAroundCenter",
          "description":
              "Flip the component horizontally around its center line.\n",
          "returns": "void"
        },
        {
          "kind": "method",
          "name": "flipVerticallyAroundCenter",
          "description":
              "Flip the component vertically around its center line.\n",
          "returns": "void"
        },
        {
          "kind": "getter",
          "name": "isFlippedHorizontally",
          "description": "Whether it is currently flipped horizontally.\n",
          "returns": "bool"
        },
        {
          "kind": "getter",
          "name": "isFlippedVertically",
          "description": "Whether it is currently flipped vertically.\n",
          "returns": "bool"
        },
        {
          "kind": "method",
          "name": "renderDebugMode",
          "parameters": {
            "all": [
              {"name": "canvas", "type": "Canvas"}
            ]
          },
          "returns": "void",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "renderTree",
          "parameters": {
            "all": [
              {"name": "canvas", "type": "Canvas"}
            ]
          },
          "returns": "void",
          "annotations": [
            {"name": "@override"}
          ]
        },
        {
          "kind": "method",
          "name": "toRect",
          "description":
              "Returns the bounding rectangle for this component.\n\nThe bounding rectangle is given in parent's coordinate space, and is\ndefined as the smallest axes-aligned rectangle that can fit this\ncomponent. The aspect ratio of the bounding rectangle may be different\nfrom [size] if the component was scaled and/or rotated.\n",
          "returns": "Rect"
        },
        {
          "kind": "method",
          "name": "toAbsoluteRect",
          "description":
              "The bounding rectangle of the component in global coordinate space.\n\nThis is similar to [toRect()], except the rectangle is projected into the\noutermost coordinate frame.\n",
          "returns": "Rect"
        },
        {
          "kind": "method",
          "name": "setByRect",
          "description":
              "Mutates position and size using the provided [rect] as basis.\nThis is a relative rect, same definition that [toRect] use\n(therefore both methods are compatible,\ni.e. setByRect ∘ toRect = identity).\n",
          "parameters": {
            "all": [
              {"name": "rect", "type": "Rect"}
            ]
          },
          "returns": "void"
        }
      ]
    },
  )..components = [],
  FlameComponentObject(
    name: 'TextComponent',
    type: 'PositionComponent',
    parameters: [
      FlameComponentField('text', 'String?', 'null'),
      FlameComponentField('textRenderer', 'T?', 'null'),
      FlameComponentField('super.position', 'dynamic', 'null'),
      FlameComponentField('super.size', 'dynamic', 'null'),
      FlameComponentField('super.scale', 'dynamic', 'null'),
      FlameComponentField('super.angle', 'dynamic', 'null'),
      FlameComponentField('super.anchor', 'dynamic', 'null'),
      FlameComponentField('super.children', 'dynamic', 'null'),
      FlameComponentField('super.priority', 'dynamic', 'null'),
      FlameComponentField('super.key', 'dynamic', 'null')
    ],
    data: {
      "kind": "class",
      "name": "TextComponent",
      "typeParameters": [
        {"name": "T", "extends": "TextRenderer"}
      ],
      "extends": "PositionComponent",
      "members": [
        {
          "kind": "constructor",
          "name": "TextComponent",
          "parameters": {
            "all": [
              {"name": "text", "type": "String?"},
              {"name": "textRenderer", "type": "T?"},
              {"name": "super.position"},
              {"name": "super.size"},
              {"name": "super.scale"},
              {"name": "super.angle"},
              {"name": "super.anchor"},
              {"name": "super.children"},
              {"name": "super.priority"},
              {"name": "super.key"}
            ],
            "named": 10
          }
        },
        {"kind": "getter", "name": "text", "returns": "String"},
        {
          "kind": "setter",
          "name": "text",
          "parameters": {
            "all": [
              {"name": "text", "type": "String"}
            ]
          }
        },
        {"kind": "getter", "name": "textRenderer", "returns": "T"},
        {
          "kind": "setter",
          "name": "textRenderer",
          "parameters": {
            "all": [
              {"name": "textRenderer", "type": "T"}
            ]
          }
        },
        {
          "kind": "method",
          "name": "render",
          "parameters": {
            "all": [
              {"name": "canvas", "type": "Canvas"}
            ]
          },
          "returns": "void",
          "annotations": [
            {"name": "@override"}
          ]
        }
      ]
    },
  )..components = []
];
