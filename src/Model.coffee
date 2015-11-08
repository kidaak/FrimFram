class Model extends Backbone.Model
  
  constructor: (attributes, options) ->
    super(attributes, options)
    @on 'add', @onAdded, @
    @on 'invalid', @onInvalid, @  

  dataState: 'standby' # or 'fetching', 'saving'

  created: -> new Date(parseInt(@id.substring(0, 8), 16) * 1000)

  onAdded: -> @dataState = 'standby'

  schema: ->
    s = @constructor.schema
    if _.isString s then app.ajv.getSchema(s)?.schema else s

  onInvalid: ->
    console.debug "Validation failed for #{@constructor.className or @}: '#{@get('name') or @}'."
    for error in @validationError
      console.debug "\t", error.dataPath, ':', error.message

  set: (attributes, options) ->
    if (@dataState isnt 'standby') and not (options.xhr or options.headers)
      throw new Error('Cannot set while fetching or saving.')

    return super(attributes, options)

  getValidationErrors: ->
    valid = app.ajv.validate(@constructor.schema or {}, @attributes)
    return app.ajv.errors if not valid

  validate: -> @getValidationErrors()

  save: (attrs, options) ->
    options = FrimFram.wrapBackboneRequestCallbacks(options)
    result = super(attrs, options)
    @dataState = 'saving' if result
    return result

  fetch: (options) ->
    options = FrimFram.wrapBackboneRequestCallbacks(options)
    @dataState = 'fetching'
    return super(options)



FrimFram.BaseModel = FrimFram.Model = Model