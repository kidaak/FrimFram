BaseModel = require 'models/BaseModel'

tv4.addSchema({
  id: 'http://my.site/schemas#bland'
  type: 'object'
  additionalProperties: false
  default: { number: 1 }
  properties:
    number: {type: 'number'}
    object: {type: 'object'}
    string: {type: 'string'}
    _id: {type: 'string'}
})

class BlandModel extends BaseModel
  @className: 'Bland'
  @schema: 'http://my.site/schemas#bland'
  urlRoot: '/db/bland'

describe 'BaseModel', ->
  
  describe 'fetching', ->
    it 'is true while the model is being fetched from the server', ->
      b = new BlandModel({})
      expect(b.fetching).toBe(false)
      b.fetch()
      expect(b.fetching).toBe(true)
      request = jasmine.Ajax.requests.mostRecent()
      request.response({status: 200, responseText: '{}'})
      expect(b.fetching).toBe(false)
      b.fetch()
      expect(b.fetching).toBe(true)
      request = jasmine.Ajax.requests.mostRecent()
      request.response({status: 404, responseText: '{}'})
      expect(b.fetching).toBe(false)
      
    it 'is false while the model is being saved to the server', ->
      b = new BlandModel({})
      b.save()
      expect(b.fetching).toBe(false)
      
  describe 'saving', ->
    it 'is true while the model is being saved to the server', ->
      b = new BlandModel({})
      expect(b.saving).toBe(false)
      b.save()
      expect(b.saving).toBe(true)
      request = jasmine.Ajax.requests.mostRecent()
      request.response({status: 200, responseText: '{}'})
      expect(b.saving).toBe(false)
      b.save()
      expect(b.saving).toBe(true)
      request = jasmine.Ajax.requests.mostRecent()
      request.response({status: 401, responseText: '{}'})
      expect(b.saving).toBe(false)
      
    it 'is false while the model is being fetched from the server', ->
      b = new BlandModel({})
      b.fetch()
      expect(b.saving).toBe(false)

  describe 'setProjection()', ->
    it 'takes an array of properties to project and adds them as a query parameter', ->
      b = new BlandModel({})
      b.setProjection ['number', 'object']
      b.fetch()
      request = jasmine.Ajax.requests.mostRecent()
      expect(decodeURIComponent(request.url).indexOf('project=number,object')).toBeGreaterThan(-1)

  describe 'get()', ->
    it 'throws an error when you try to get properties which are not included in the projection', ->
      b = new BlandModel({}, {project: ['a']})
      b.fetch()
      request = jasmine.Ajax.requests.mostRecent()
      request.response({status: 200, responseText: '{a:1}'})
      expect(-> b.get('b')).toThrow()
      
    it 'returns default values if the second argument is true', ->
      b = new BlandModel({})
      expect(b.get('number', true)).toBe(1)
      
  describe 'set()', ->
    it 'throws an error when you try to set properties which are not included in the projection', ->
      b = new BlandModel({}, {project: ['a']})
      b.fetch()
      request = jasmine.Ajax.requests.mostRecent()
      request.response({status: 200, responseText: '{a:1}'})
      expect(-> b.set('b', 2)).toThrow()

    it 'throws an error when you try to set properties while saving', ->
      b = new BlandModel({})
      b.save()
      expect(-> b.set('a', 1)).toThrow()

    it 'throws an error when you try to set properties while fetching', ->
      b = new BlandModel({})
      b.fetch()
      expect(-> b.set('a', 1)).toThrow()

  describe 'unset()', ->
    it 'actually removes the property from attributes', ->
      b = new BlandModel({'a':'b'})
      b.unset('a')
      expect('a' in _.keys(b.attributes)).toBe(false)

  describe 'save()', ->
    it 'saves to db/<urlRoot>', ->
      b = new BlandModel({})
      res = b.save()
      request = jasmine.Ajax.requests.mostRecent()
      expect(res).toBeDefined()
      expect(request.url).toBe(b.urlRoot)
      expect(request.method).toBe('POST')

    it 'does not save if the data is invalid based on the schema', ->
      b = new BlandModel({number: 'NaN'})
      res = b.save()
      expect(res).toBe(false)
      request = jasmine.Ajax.requests.mostRecent()
      expect(request).toBeUndefined()

    it 'uses PUT when _id is included', ->
      b = new BlandModel({_id: 'test'})
      b.save()
      request = jasmine.Ajax.requests.mostRecent()
      expect(request.method).toBe('PUT')
      
  describe 'schema()', ->
    it 'dereferences the class property "schema" if it\'s a string using tv4.getSchema', ->
      b = new BlandModel()
      expect(b.schema().id).toBe('http://my.site/schemas#bland')

  describe 'fetch()', ->
    it 'straight up fetches from the url root if no other guidance is given', ->
      b = new BlandModel({})
      b.fetch()
      request = jasmine.Ajax.requests.mostRecent()
      expect(request.url).toBe('/db/bland')

    it 'can take data parameters to include in the GET request', ->
      b = new BlandModel({})
      b.fetch({data: {'slug':'mayo'}})
      request = jasmine.Ajax.requests.mostRecent()
      expect(request.url).toBe('/db/bland?slug=mayo')
      
    it 'will use a url set directly to the instance', ->
      b = new BlandModel({})
      b.url = '/db/user/1/most-recent-bland'
      b.fetch()
      request = jasmine.Ajax.requests.mostRecent()
      expect(request.url).toBe('/db/user/1/most-recent-bland')
      
    it 'will use an id passed into the constructor', ->
      b = new BlandModel({_id: '1'})
      b.fetch()
      request = jasmine.Ajax.requests.mostRecent()
      expect(request.url).toBe('/db/bland/1')
      
    it 'will set its url value to a direct value on success', ->
      b = new BlandModel({})
      b.fetch()
      request = jasmine.Ajax.requests.mostRecent()
      request.response({status: 200, responseText: '{"_id":1}'})
      expect(b.url).toBe('/db/bland/1')
      
  describe 'patch()', ->
    it 'PATCHes only properties that have changed', ->
      b = new BlandModel({_id: 'test', number: 1})
      b.loaded = true
      b.set('string', 'string')
      b.patch()
      request = jasmine.Ajax.requests.mostRecent()
      params = JSON.parse request.params
      expect(params.string).toBeDefined()
      expect(params.number).toBeUndefined()

    it 'collates all changes made over several sets', ->
      b = new BlandModel({_id: 'test', number: 1})
      b.loaded = true
      b.set('string', 'string')
      b.set('object', {4: 5})
      b.patch()
      request = jasmine.Ajax.requests.mostRecent()
      params = JSON.parse request.params
      expect(params.string).toBeDefined()
      expect(params.object).toBeDefined()
      expect(params.number).toBeUndefined()

    it 'does not include data from previous patches', ->
      b = new BlandModel({_id: 'test', number: 1})
      b.loaded = true
      b.set('object', {1: 2})
      b.patch()
      request = jasmine.Ajax.requests.mostRecent()
      attrs = JSON.stringify(b.attributes) # server responds with all
      request.response({status: 200, responseText: attrs})

      b.set('number', 3)
      b.patch()
      request = jasmine.Ajax.requests.mostRecent()
      params = JSON.parse request.params
      expect(params.object).toBeUndefined()

    it 'does nothing when there\'s nothing to patch', ->
      b = new BlandModel({_id: 'test', number: 1})
      b.loaded = true
      b.patch()
      request = jasmine.Ajax.requests.mostRecent()
      expect(request).toBeUndefined()
      
  describe 'revert()', ->
    it 'sets attributes back to the data when initialized', ->
      b = new BlandModel({prop: 'value'})
      b.set('prop', 'new value')
      expect(b.attributes.prop).toBe('new value')
      b.revert()
      expect(b.attributes.prop).toBe('value')

  describe 'permissions', ->
  
  describe 'deltas', ->