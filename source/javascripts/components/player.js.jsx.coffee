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
    @timerInterval = setInterval @updateClock, 1000

  componentWillUnmount: ->
    if @timerInterval?
      clearInterval @timerInterval

  updateClock: ->
    console.log 'updateClock'
    @setState duration: @props.game.playerTimes()[@props.color]

  render: ->
    stoneClassNames = "stone stone--#{@props.color}"

    if @state.user
      if @state.user.provider is 'twitter'
        avatarPath = "http://avatars.io/twitter/#{@state.user.username}?size=small"
      else
        avatarPath = "http://www.gravatar.com/avatar/#{@state.user.email}?s=50&d=identicon"
      displayName = @state.user.displayName or "Unknown"
      onlineState = if @state.currently_online then 'Online' else "Offline (since #{moment.duration(@state.user.lastOnline - new Date().valueOf()).humanize()} ago)"
    else
      displayName = 'Loading player info...'
      onlineState = ''

    `<li>
      <div className='player-info'>
        <div className={stoneClassNames}></div>
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
          <div className='player-passed'>passed</div>
            : ''
        }
        Total time: {secondsToTime(this.state.duration)}
        <br />
        Prisoners: {this.props.game.prisoners[this.props.color] }
      </div>
    </li>`

window.PlayerSpotView = React.createClass
  joinGame: ->
    @props.joinGame(@props.color)

  render: ->
    stoneClassNames = "stone stone--#{@props.color}"

    `<li className='waiting'>
      <div className='player-info'>
        <div className={stoneClassNames}></div>
        <div className='player-name'> Waiting for player to join...  </div>
      </div>
      <input className="join-btn" type="button" value="Join" onClick={this.joinGame} />
    </li>`


