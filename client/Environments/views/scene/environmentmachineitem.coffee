class EnvironmentMachineItem extends EnvironmentItem

  JView.mixin @prototype

  constructor:(options={}, data)->

    options.cssClass           = 'machine'
    options.joints             = ['left']

    options.allowedConnections =
      EnvironmentDomainItem    : ['right']

    super options, data

    @terminalIcon = new KDCustomHTMLView
      tagName     : "span"
      cssClass    : "terminal hidden"
      click       : @bound "openTerminal"

    @progress = new KDProgressBarView
      cssClass : "progress hidden"

    { status: {state} } = @getData()

    @setClass state.toLowerCase()

    if state is "Running"
      @terminalIcon.show()


  contextMenuItems : ->

    colorSelection = new ColorSelection selectedColor : @getOption 'colorTag'
    colorSelection.on "ColorChanged", @bound 'setColorTag'

    vmName = @getData().hostnameAlias
    vmAlwaysOnSwitch = new VMAlwaysOnToggleButtonView null, {vmName}
    items =
      customView4         : vmAlwaysOnSwitch
      'Build Machine'     :
        callback          : =>
          machine = this.getData()
          kloud = KD.singletons.kontrol.getKite {
            name:"kloud", environment:"vagrant"
          }
          kloud.build(machineId: machine._id).then(log, warn)

      'Re-initialize VM'  :
        disabled          : KD.isGuest()
        callback          : ->
          KD.getSingleton("vmController").reinitialize vmName
          @destroy()
      'Open VM Terminal'  :
        callback          : =>
          @openTerminal()
          @destroy()
        separator         : yes
      'Update init script':
        separator         : yes
        callback          : @bound "showInitScriptEditor"
      'Delete'            :
        disabled          : KD.isGuest()
        separator         : yes
        action            : 'delete'
      customView3         : colorSelection

    return items

  openTerminal:->
    vmName = @getData().hostnameAlias
    KD.getSingleton("router").handleRoute "/Terminal", replaceState: yes
    KD.getSingleton("appManager").open "Terminal", params: {vmName}, forceNew: yes

  confirmDestroy:->
    KD.getSingleton('vmController').remove @getData().hostnameAlias, @bound "destroy"

  showInitScriptEditor: ->

    modal =  new EditorModal
      editor              :
        title             : "VM Init Script Editor <span>(experimental)</span>"
        content           : @data.meta?.initScript or ""
        saveMessage       : "VM init script saved"
        saveFailedMessage : "Couldn't save VM init script"
        saveCallback      : (script, modal) =>
          KD.remote.api.JVM.updateInitScript @data.hostnameAlias, script, (err, res) =>
            if err
              modal.emit "SaveFailed"
            else
              modal.emit "Saved"
              @data.meta or= {}
              @data.meta.initScript = Encoder.htmlEncode modal.editor.getValue()


  pistachio:->

    {label, provider, ipAddress, status:{state} } = @getData()
    title = label or provider

    publicUrl = if ipAddress? then """
      <a href="http://#{ipAddress}" target="_blank" title="#{ipAddress}">
        <span class='url'>#{ipAddress}</span>
      </a>
    """ else ""

    """
      <div class='details'>
        <span class='toggle'></span>
        <h3>#{title}</h3>
        #{publicUrl}
        <span class='state'>#{state}</span>
        {{> @progress}}
        {{> @terminalIcon}}
        {{> @chevron}}
      </div>
    """
