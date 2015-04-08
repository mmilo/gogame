###* @jsx React.DOM ###

window.PlayerView = React.createClass
  getInitialState: ->
    user: null
    currently_online: false
    duration: null

  componentWillMount: ->
    # Observe player
    @props.firebase.child('users').child(@props.uid).on 'value', (snap) =>
      @setState(user: snap.val())
    # Observe player online state
    @props.firebase.child('presence').child(@props.uid).on 'value', (snap) =>
      @setState(currently_online: snap.val()?)

    # Update the game clock every second
    @timerInterval = setInterval((=> @render()), 1000)

  componentWillUnmount: ->
    clearInterval(@timerInterval) if @timerInterval?

  render: ->
    stoneClassNames = "stone stone--#{@props.color}"
    duration = @props.game.playerTimes()[@props.color]

    if @state.user
      if @state.user.provider is 'twitter'
        avatarPath = "http://avatars.io/twitter/#{@state.user.username}?size=small"
      else
        avatarPath = "http://www.gravatar.com/avatar/#{md5(@state.user.displayName+'')}?s=50&d=retro"
      displayName = @state.user.displayName or "Unknown"
      onlineState = if @state.currently_online then 'Online' else "Offline (since #{moment.duration(@state.user.lastOnline - new Date().valueOf()).humanize()} ago)"
    else
      displayName = 'Loading player info...'
      onlineState = ''

    `<li>
      <div className='player-info'>
        <div className='player-stone-container'>
          <div className={stoneClassNames}></div>
        </div>
        <div className='player-name'>
          { displayName }
        </div>
        <div className='player-online-status'>
          { onlineState }
        </div>
        { avatarPath ?
          <img src={avatarPath} className='player-avatar'/>
          : ''
        }
      </div>
      <div className='player-game-info'>
        {
          this.props.game.showPlayerPassed(this.props.color) ?
          <div className='player-badge player-passed'>passed</div>
            : ''
        }
        {
          this.props.game.showPlayerResigned(this.props.color) ?
          <div className='player-badge player-resigned'>resigned</div>
            : ''
        }
        Total time: {secondsToTime(duration)}
        <br />
        Prisoners: {this.props.game.prisoners[Go.otherColor(this.props.color)] }
      </div>
    </li>`

window.PlayerSpotView = React.createClass
  joinGame: ->
    @props.joinGame(@props.color)

  render: ->
    stoneClassNames = "stone stone--#{@props.color}"

    `<li className='waiting'>
      <div className={stoneClassNames}></div>
      <span>This position is open. Want to play?</span>
      <br />
      <input className="join-btn" type="button" value={"Join as "+this.props.color} onClick={this.joinGame} />
    </li>`


