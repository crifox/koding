class ClassroomClassThumbView extends JView

  constructor: (options = {}, data) ->

    options.tagName = "figure"

    super options, data

    @createElements()

    data    = @getData()
    appView = @getDelegate()

    @on "EnrollmentCancelled", => appView.cancelEnrollment data
    @on "EnrollmentRequested", => appView.enrollToClass data

  createElements: ->
    data              = @getData()
    devModeOptions    = {}
    cancelIconOptions = {}

    if data.devMode
      devModeOptions.cssClass = "top-badge gray"
      devModeOptions.partial  = "Dev Mode"

    @devMode = new KDCustomHTMLView devModeOptions

    if @getOptions().type is "enrolled"
      cancelIconOptions.tagName  = "span"
      cancelIconOptions.cssClass = "icon delete"
      cancelIconOptions.click    = (e) =>
        e.stopPropagation()
        @destroy()
        @emit "EnrollmentCancelled"

    @cancelIcon = new KDCustomHTMLView cancelIconOptions
    @loader     = new KDLoaderView
      size      :
        width   : 40

    @loader.hide()

  click: ->
    log "should open class"
    @emit "EnrollmentRequested", @getData()  if @getOptions().type isnt "enrolled"

  pistachio: ->
    data      = @getData()
    {cdnRoot} = @getOptions()
    return """
      {{> @devMode}}
      <p>
        <img src="#{cdnRoot}/#{data.name}.kdclass/#{data.icns['128']}" />
      </p>
      <div class="icon-container">
        {{> @cancelIcon}}
      </div>
      <cite>
        <span>#{data.name}</span>
        <span>#{data.version}</span>
      </cite>
      {{> @loader}}
    """
