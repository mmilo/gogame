###* @jsx React.DOM ###

window.PlayerView = React.createClass
  render: ->
    colorName = if @props.color is Go.BLACK then 'black' else 'white'
    stoneClassNames = "stone stone--#{colorName}"

    if @props.user
      avatarPath = "twitter/#{@props.user.username}"
    else
      avatarPath = null
    `<li className={this.props.uid ? '' : 'waiting'}>
      <div className='player-online-status'>
        { this.props.user ?
            this.props.user.connections ? 'Online' : "Offline (since "+this.props.user.lastOnline+")"
          : ''
        }

        { avatarPath ?
          <img src={"http://avatars.io/"+avatarPath} />
          : ''
        }
      </div>
      <div className={stoneClassNames}></div>
      {
        this.props.uid ?
          this.props.user ? this.props.user.displayName : 'Loading player info...'
        :
          'Waiting for player to join...'
      }
      {this.props.game[colorName+'Passed']() ? " ---  [ PASSED ]" : ''}
      <br />
      {moment.duration(this.props.duration).humanize()}
      <br />
      {this.props.game.prisoners[this.props.color] }
      &nbsp; prisoners
    </li>`
