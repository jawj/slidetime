
# naughtily optimised version that may append one or two trailing zero bytes

b64 = (input, output = '') ->
  chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/='.split ''
  len = input.length
  i = 0
  while i < len
    chr1 = input[i++]
    chr2 = input[i++]
    chr3 = input[i++]
    output += chars[chr1 >> 2]
    output += chars[((chr1 & 3) << 4) | (chr2 >> 4)]
    output += chars[((chr2 & 15) << 2) | (chr3 >> 6)]
    output += chars[chr3 & 63]
  output


# concise interface to getElementById, getElementsByTagName, getElementsByClassName
# opts: either id *or* tag and/or cls, [inside], [multi]
# id is an id, tag is a tag name
# cls is a space-separated list of class names: element must satisfy all (plus tag, if present)
# if id or a unique tag (body, head, etc) specified, returns one element, else returns an array
# depends on: cls

get = (opts = {}) ->
  inside = opts.inside ? document
  tag = opts.tag ? '*'
  if opts.id?
    return inside.getElementById opts.id
  hasCls = opts.cls?
  if hasCls and tag is '*' and inside.getElementsByClassName?
    return inside.getElementsByClassName opts.cls
  els = inside.getElementsByTagName tag
  if hasCls then els = (el for el in els when cls el, has: opts.cls)
  if not opts.multi? and tag.toLowerCase() in get.uniqueTags then els[0] ? null else els

get.uniqueTags = 'html body frameset head title base'.split(' ')


# easy className-wrangling: both querying and modifying
# opts: either has *or* add and/or remove and/or toggle
# all opt values are space-separated lists of class names
# depends on: none

cls = (el, opts = {}) ->
  classHash = {}
  classes = (el.className ? '').match(cls.re)
  if classes?
    (classHash[c] = yes) for c in classes
  hasClasses = opts.has?.match(cls.re)
  if hasClasses?
    (return no unless classHash[c]) for c in hasClasses
    return yes
  addClasses = opts.add?.match(cls.re)
  if addClasses?
    (classHash[c] = yes) for c in addClasses
  removeClasses = opts.remove?.match(cls.re)
  if removeClasses?
    delete classHash[c] for c in removeClasses
  toggleClasses = opts.toggle?.match(cls.re)
  if toggleClasses?
    for c in toggleClasses
      if classHash[c] then delete classHash[c] else classHash[c] = yes
  el.className = (k for k of classHash).join ' '
  null

cls.re = /\S+/g


# concise creating, setting attributes and appending of elements
# opts: tag, parent, prevSib, text, cls, [attrib]
# depends on: text

make = (opts = {}) ->
  t = document.createElement opts.tag ? 'div'
  for own k, v of opts
    switch k
      when 'tag' then continue
      when 'parent' then v.appendChild t
      when 'kids' then t.appendChild c for c in v when c?
      when 'prevSib' then v.parentNode.insertBefore t, v.nextSibling
      when 'text' then t.appendChild text v
      when 'cls' then t.className = v
      when 'style' then t.style[sk] = sv for sk, sv of v
      when 'attrs' then t.setAttribute(ak, av) for ak, av of v
      else t[k] = v
  t

text = (t) -> document.createTextNode '' + t


xhr = (opts = {}) ->
  method = opts.method ? 'GET'
  req = new XMLHttpRequest()
  req.onreadystatechange = -> 
    if req.readyState is 4 and (req.status is 200 or not location.href.match /^https?:/)
      opts.success(req)
  req.overrideMimeType opts.mime if opts.mime?
  req.user = opts.user if opts.user?
  req.password = opts.password if opts.password?
  req.setRequestHeader k, v for k, v of opts.headers if opts.headers?
  req.open method, opts.url
  if opts.type is 'binString'
    req.overrideMimeType 'text/plain; charset=x-user-defined'
  else if opts.type?
    req.responseType = opts.type
  req.send opts.data
  yes


class @ParallelWaiter  # waits for parallel async jobs
  constructor: (@waitingFor, @cb) -> @returnValues = {}
  await: (n = 1) -> @waitingFor += n
  done: (returnValues = {}) ->
    (@returnValues[k] = v) for k, v of returnValues
    @cb(@returnValues) if --@waitingFor is 0
