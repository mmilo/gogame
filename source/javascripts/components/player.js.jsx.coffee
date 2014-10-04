###* @jsx React.DOM ###

window.PlayerView = React.createClass
  render: ->
    colorName = if @props.color is Go.BLACK then 'black' else 'white'
    stoneClassNames = "stone stone--#{colorName}"

    if @props.user
      if @props.user.provider is 'twitter'
        avatarPath = "http://avatars.io/twitter/#{@props.user.username}?size=small"
      else
        avatarPath = "http://www.gravatar.com/avatar/#{@props.user.email}?s=50&d=identicon"
      displayName = @props.user.displayName or "Unknown"
    else
      displayName = 'Loading player info...'

    `<li className={this.props.uid ? '' : 'waiting'}>
      <div className='player-info'>
        <div className={stoneClassNames}></div>
        <div className='player-name'>
          {
            this.props.uid ?
              displayName
            :
              'Waiting for player to join...'
          }
        </div>
        <div className='player-online-status'>
          { this.props.user ?
              this.props.user.connections ? 'Online' : "Offline (since "+this.props.user.lastOnline+")"
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
          this.props.game[colorName+'Passed']() ?
          <div className='player-passed'>passed</div>
            : ''
        }
        Total time: {secondsToTime(this.props.duration)}
        <br />
        Prisoners: {this.props.game.prisoners[this.props.color] }
      </div>
    </li>`
