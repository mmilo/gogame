###* @jsx React.DOM ###

window.PlayerView = React.createClass
  render: ->
    colorName = if @props.color is Go.BLACK then 'black' else 'white'
    stoneClassNames = "stone stone--#{colorName}"

    `<li className={this.props.uid ? '' : 'waiting'}>
      <div className={stoneClassNames}></div>
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
      {moment.duration(this.props.duration).humanize()}
      <br />
      {this.props.game.prisoners[this.props.color] }
      &nbsp; prisoners
    </li>`
