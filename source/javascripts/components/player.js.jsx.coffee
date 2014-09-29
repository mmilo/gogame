PlayerView = React.createClass
  render: ->
    colorName = if @props.color is Go.BLACK then 'black' else 'white'

    `<li className={this.props.uid ? '' : 'waiting'}>
      <div className='stone stone--black'></div>
      {
        this.props.uid ?
          this.props.user ? this.props.user.displayName : 'Loading player info...'
        :
          'Waiting for player to join...'
      }
      { this.props.user ?
          this.props.user.connections ? 'Online' : "Offline (since "+this.props.user.lastOnline+")"
        : ''
      }
      {this.props.game[colorName+'Passed']() ? " ---  [ PASSED ]" : ''}
      <br />
      {moment.duration(this.props.player_times[this.props.color]).humanize()}
      <br />
      {this.props.game.prisoners[this.props.color] }
      &nbsp; prisoners
    </li>`
