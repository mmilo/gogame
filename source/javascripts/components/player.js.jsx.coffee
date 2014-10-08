###* @jsx React.DOM ###

window.PlayerView = React.createClass
  getInitialState: ->
    currently_online: false

  componentWillMount: ->
    @props.firebase.child('presence').child(@props.user.uid).on 'value', (snap) =>
      @setState currently_online: snap.val()?

  render: ->
    stoneClassNames = "stone stone--#{@props.color}"

    if @props.user
      if @props.user.provider is 'twitter'
        avatarPath = "http://avatars.io/twitter/#{@props.user.username}?size=small"
      else
        avatarPath = "http://www.gravatar.com/avatar/#{@props.user.email}?s=50&d=identicon"
      displayName = @props.user.displayName or "Unknown"
    else
      displayName = 'Loading player info...'

    `<li>
      <div className='player-info'>
        <div className={stoneClassNames}></div>
        <div className='player-name'>
          { displayName }
        </div>
        <div className='player-online-status'>
          { this.props.user ?
              this.state.currently_online ? 'Online' : "Offline (since "+moment.duration((this.props.user.lastOnline - (new Date()).valueOf())).humanize()+" ago)"
            : ''
          }
        </div>
        { avatarPath ?
          <img src={avatarPath} className='player-avatar'/>
          : ''
        }
      </div>
      <div className='player-game-info'>
        {
          this.props.game[this.props.color+'Passed']() ?
          <div className='player-passed'>passed</div>
            : ''
        }
        Total time: {secondsToTime(this.props.duration)}
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


