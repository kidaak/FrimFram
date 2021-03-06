crypto = require 'crypto'
config = rootRequire 'server/server-config'
mongoose = require 'mongoose'
UserSchema = new mongoose.Schema({}, {strict: false, minimize: false})


#- middleware

UserSchema.pre 'save', (next) ->
  if email = @get('email')
    @set('emailLower', email.toLowerCase())

  if name = @get('name')
    @set('slug', _.kebabCase(name))
  
  if pwd = @get('password')
    @set('passwordHash', User.hashPassword(pwd))
    @set('password', undefined)

  next()


#- static methods

UserSchema.statics.hashPassword = (password) ->
  password = password.toLowerCase()
  shasum = crypto.createHash('sha512')
  shasum.update(config.salt + password)
  return shasum.digest('hex')
  

User = mongoose.model('User', UserSchema)
#User.jsonSchema = tv4.getSchema('http://my.site/schemas#user')

module.exports = User