
class @Dropdown
  scrollGap: 10

  constructor: (@input, @dropdown, @callback) ->
    @input.addEventListener 'focus', @show
    @input.addEventListener 'blur',  @hideSoon  # looks better, plus immediate hide means no click event gets registered
    @dropdown.addEventListener 'click', @dropdownClickListener
    @dropdown.addEventListener 'mouseover', @dropdownMouseListener
    @input.addEventListener 'keydown', @inputKeyListener

  dropdownClickListener: (e) => 
    @update() 

  dropdownMouseListener: (e) =>
    targetRow = @findAncestor e.target, (node) -> cls node, has: 'fc-row'
    if targetRow
      rows = get cls: 'fc-row', inside: @dropdown
      for row in rows
        if row is targetRow then cls row, add:    'fc-highlighted'
        else                     cls row, remove: 'fc-highlighted'
      @scrollHighlightedIntoView()

  inputKeyListener: (e) =>
    kc = e.keyCode
    return unless kc in [13, 38, 40]
    
    e.preventDefault()

    if kc is 13
      @update()
      @input.blur()
      return

    change = if kc is 38 then -1 else if kc is 40 then 1

    oldIndex = -1
    rows = get cls: 'fc-row', inside: @dropdown
    for row, i in rows
      if (cls row, has: 'fc-highlighted')
        oldIndex = i
        break
    newIndex = oldIndex + change
    if newIndex < 0 then newIndex = rows.length - 1
    if newIndex >= rows.length then newIndex = 0
    
    cls rows[oldIndex], remove: 'fc-highlighted' if oldIndex >= 0
    cls rows[newIndex],    add: 'fc-highlighted'

    @scrollHighlightedIntoView()

  scrollHighlightedIntoView: ->
    row = (get cls: 'fc-highlighted', inside: @dropdown)[0]

    ddVisTop = @dropdown.scrollTop + @scrollGap
    ddVisBtm = @dropdown.scrollTop + @dropdown.clientHeight - @scrollGap
    rowTop = row.offsetTop
    rowBtm = rowTop + row.clientHeight

    @dropdown.scrollTop = rowTop - @scrollGap if rowTop < ddVisTop
    @dropdown.scrollTop = rowBtm - @dropdown.clientHeight + @scrollGap if rowBtm > ddVisBtm

  update: =>
    valueNode = (get cls: 'fc-highlighted', inside: @dropdown)[0]
    if valueNode
      value = valueNode.getAttribute 'data-dropdown-value'
      @input.value = value
      @callback value

  show: =>
    @dropdown.style.display = 'block'
    @resize()
    window.addEventListener 'scroll', @resize
    window.addEventListener 'resize', @resize
    
  hide: =>
    @dropdown.style.display = 'none'
    window.removeEventListener 'scroll', @resize
    window.removeEventListener 'resize', @resize

  hideSoon: => setTimeout @hide, 150

  resize: =>
    winHeight = window.innerHeight
    inputWinRect = @input.getBoundingClientRect()
    inputPageX = inputWinRect.left + window.scrollX
    if inputWinRect.top > winHeight / 2
      dropdownPageY = window.scrollY + 1
      dropdownHeight = inputWinRect.top - 5
    else
      dropdownPageY = inputWinRect.bottom + window.scrollY + 1
      dropdownHeight = winHeight - inputWinRect.bottom - 10
    @dropdown.style.top = dropdownPageY + 'px'
    @dropdown.style.left = inputPageX + 'px'
    @dropdown.style.height = dropdownHeight + 'px'

  findAncestor: (node, callback) ->
    return null unless node
    return node if callback node
    return @findAncestor node.parentNode, callback

  findAncestorResult: (node, callback) ->
    return null unless node
    result = callback node
    return result if result
    return @findAncestorResult node.parentNode, callback


@FontChooser = (sampleText = 'Aa Bb Cc', width = 250, extraCandidates, callback) ->
  chooser = make tag: 'input', cls: 'fc-chooser', value: 'Helvetica Neue', style: {width: "#{width}px"}
  cont = make parent: (get tag: 'body'), cls: 'fc-container', style: {width: "#{width}px"}
  localFonts = new LocalFonts()
  fonts = localFonts.listCommonInstalled extraCandidates
  for font in fonts
    row    = make parent: cont, cls: 'fc-row', attrs: {'data-dropdown-value': font}
    sample = make parent: row,  cls: 'fc-sample', text: sampleText, style: {fontFamily: font}
    title  = make parent: row,  cls: 'fc-title',  text: font
  new Dropdown chooser, cont, (callback ? (->))

@FontSizeChooser = (sampleText = 'Aa Bb Cc', width = 250, sizes = [12, 14, 18, 24, 36, 48, 60, 72, 96, 144, 288], callback) ->
  chooser = make tag: 'input', cls: 'fc-chooser', value: '60', style: {width: "50px"}
  cont = make parent: (get tag: 'body'), cls: 'fc-container', style: {width: "#{width}px"}
  for size in sizes
    row    = make parent: cont, cls: 'fc-row', attrs: {'data-dropdown-value': size}
    sample = make parent: row,  cls: 'fc-sample', text: sampleText, style: {fontSize: "#{size}pt"}
    title  = make parent: row,  cls: 'fc-title',  text: size
  new Dropdown chooser, cont, (callback ? (->))
  
class LocalFonts

  listInstalled: (candidateFonts) ->
    body = get tag: 'body'
    span = make tag: 'span', text: 'iii', style: {fontSize: '16px', visibility: 'hidden'}, parent: body
    installedFonts = []
    for candidateFont in candidateFonts
      widths = for baseFont in ['serif', 'monospace']
        span.style.fontFamily = "'#{candidateFont}', #{baseFont}"
        span.offsetWidth
      installedFonts.push candidateFont if widths[0] is widths[1]
    body.removeChild span
    installedFonts.sort()

  listCommonInstalled: (extraCandidates = []) ->
    @listInstalled(@candidateFonts.concat extraCandidates)

  isInstalled: (font) ->
    @listInstalled([font]).length > 0
  
  candidateFonts: [  # Latin alphabet fonts from OS X, Windows, Ubuntu and Adobe, plus a few extras 
    'Academy Engraved'
    'Adobe Caslon Pro'
    'Adobe Garamond Pro'
    'Adobe Gothic Std'
    'Agency FB'
    'Algerian'
    'American Typewriter'
    'Andale Mono'
    'Apple Chancery'
    'Arial'
    'Arial Black'
    'Arial Narrow'
    'Arial Rounded Bold'
    'Arial Rounded MT Bold'
    'Baskerville'
    'Baskerville Old Face'
    'Bauhaus 93'
    'Bell MT'
    'Berlin Sans FB'
    'Bernard MT Condensed'
    'Big Caslon'
    'Birch Std'
    'Bitstream Charter'
    'Blackadder ITC'
    'Blackoak Std'
    'Bodoni 72 Oldstyle'
    'Bodoni 72 Smallcaps'
    'Bodoni MT'
    'Book Antiqua'
    'Bookman Old Style'
    'Bradley Hand'
    'Bradley Hand ITC'
    'Britannic Bold'
    'Broadway'
    'Brush Script'
    'Brush Script MT Italic'
    'Calibri'
    'Californian FB'
    'Calisto MT'
    'Cambria'
    'Candara'
    'Castellar'
    'Centaur'
    'Century'
    'Century Gothic'
    'Century Schoolbook'
    'Century Schoolbook L'
    'Chalkboard'
    'Chalkduster'
    'Chaparral Pro'
    'Charcoal'
    'Charcoal CY'
    'Charlemagne Std'
    'Chicago'
    'Chiller'
    'Cochin'
    'Colonna MT'
    'Comic Sans MS'
    'Consolas'
    'Constantia'
    'Cooper'
    'Cooper Black'
    'Cooper Std'
    'Copperplate'
    'Copperplate Gothic Light'
    'Corbel'
    'Courier'
    'Courier 10 Pitch'
    'Courier New'
    'Curlz MT'
    'Deja Vu Sans Mono'
    'DejaVu Sans'
    'DejaVu Serif'
    'Didot'
    'Edwardian Script ITC'
    'Elephant'
    'Engravers MT'
    'Eras Medium ITC'
    'Felix Titling'
    'Footlight MT Light'
    'Forte'
    'Franklin Gothic Medium'
    'FreeMono'
    'FreeSans'
    'FreeSerif'
    'Freestyle Script'
    'French Script MT'
    'Futura'
    'Gabriola'
    'Garamond'
    'Geneva'
    'Georgia'
    'Giddyup Std'
    'Gigi'
    'Gill Sans'
    'Gill Sans MT'
    'Gloucester MT Extra Condensed'
    'Goudy Old Style'
    'Goudy Stout'
    'Haettenschweiler'
    'Harlow Solid Italic'
    'Harrington'
    'Helvetica'
    'Helvetica Neue'
    'Herculanum'
    'High Tower Text'
    'Hobo Std'
    'Hoefler Text'
    'Impact'
    'Imprint MT Shadow'
    'Informal Roman'
    'Jokerman'
    'Juice ITC'
    'Kristen'
    'Kunstler Script'
    'Letter Gothic'
    'Letter Gothic Std'
    'Liberation Mono'
    'Liberation Sans'
    'Lithos Pro'
    'Lucida Bright'
    'Lucida Calligraphy'
    'Lucida Console'
    'Lucida Fax'
    'Lucida Grande'
    'Lucida Handwriting'
    'Lucida Sans Typewriter'
    'Lucida Sans Unicode'
    'Magneto Bold'
    'Maiandra GD'
    'Marker Felt'
    'Matura MT Script Capitals'
    'Menlo'
    'Mesquite Std'
    'Microsoft Sans Serif'
    'Minion Pro'
    'Mistral'
    'Modern No. 20'
    'Monaco'
    'Monotype Corsiva'
    'Myriad Pro'
    'Niagara Engraved'
    'Niagara Solid'
    'Nimbus Mono L'
    'Nimbus Roman No9 L'
    'Nimbus Sans L'
    'Noteworthy'
    'Nueva Std'
    'OCR A Extended'
    'OCRA Std'
    'Old English Text MT'
    'Optima'
    'Orator Std'
    'PT Sans'
    'Palace Script MT'
    'Palatino'
    'Palatino Linotype'
    'Papyrus'
    'Perpetua'
    'Perpetua Titling MT Light'
    'Playbill'
    'Poor Richard'
    'Poplar Std'
    'Prestige Elite Std'
    'Pristina'
    'Rage Italic'
    'Ravie'
    'Roboto'
    'Rockwell'
    'Rosewood Std Regular'
    'Script MT Bold'
    'Segoe Print'
    'Segoe Script'
    'Segoe UI'
    'Skia'
    'Snell Roundhand'
    'Source Sans Pro'
    'Stencil'
    'Stencil Std'
    'Tahoma'
    'Tekton Pro Bold'
    'Times'
    'Times New Roman'
    'Trajan Pro'
    'Trebuchet MS'
    'Tw Cen MT'
    'URW Bookman L'
    'URW Chancery L'
    'URW Gothic L'
    'URW Palladio L'
    'Ubuntu'
    'Verdana'
    'Viner Hand'
    'Vivaldi Italic'
    'Vladimir Script'
    'Wide Latin'
    'Zapf Chancery'
    'Zapfino'
  ]