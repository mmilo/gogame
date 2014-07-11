###* @jsx React.DOM ###
BoardIntersection = React.createClass
  handleClick: ->
    @props.onPlay() if @props.game.play([@props.row, @props.col])
    return

  render: ->
    classes = "point "
    classes += (if @props.color is Go.BLACK then "stone stone--black" else "stone stone--white")  unless @props.color is Go.EMPTY
    `<td onClick={this.handleClick} className={classes}></td>`

BoardRow = React.createClass
  render: ->
    `<tr className='row'>{this.props.intersections}</tr>`

BoardView = React.createClass
  render: ->
    rows = []
    i = 0

    while i < @props.game.size
      intersections = []
      j = 0

      while j < @props.game.size
        intersections.push BoardIntersection(
          game: @props.game
          color: @props.game.board[i][j]
          row: i
          col: j
          onPlay: @props.onPlay
        )
        j++
      rows.push BoardRow(intersections: intersections)
      i++
    boardClass = "board turn turn--" + ((if @props.game.current_color() is Go.BLACK then "black" else "white"))
    `<div className='table'>
      <div className={boardClass}>
        <table className='grid'>
          {rows}
        </table>
      </div>
    </div>`

AlertView = React.createClass
  render: ->
    text = ""
    if @props.game.in_atari
      text = "ATARI!"
    else if @props.game.attempted_suicide
      text = "SUICIDE!"
    `<div id="alerts">{text}</div>`

PassView = React.createClass
  handleClick: (e) ->
    @props.game.play('pass')

  render: ->
    `<input id="pass-btn" type="button" value="Pass" onClick={this.handleClick} />`

PlayersView = React.createClass
  componentWillMount: ->
    @props.game.on('change:player1 change:player2', =>
      @setState(game: @props.game)
    )

  handleClick: ->
    console.log "Joining!"
    if Go.current_user?
      console.log 'uid '+ Go.current_user.uid
      userId = Go.current_user.uid
    else
      auth.login('twitter', {preferRedirect: true, rememberMe: true})
      return

    if !@props.game.get('player1')
      @props.game.set('player1', userId)
    else if !@props.game.get('player2')
      @props.game.set('player2', userId)
    @props.onPlayerAdd()

  render: ->
    player1 = @props.game.get('player1')
    player2 = @props.game.get('player2')

    `<div className='players'>
      <p>{player1 ? player1 : 'waiting for player 1 to join...'}</p>
      <p>{player2 ? player2 : 'waiting for player 2 to join...'}</p>
      {!player1 || !player2 ? <input id="join-btn" type="button" value="Join" onClick={this.handleClick} /> : ''}
    </div>
    `


ContainerView = React.createClass
  getInitialState: ->
    {game: @props.game}

  componentWillMount: ->
    @props.game.on('board_state_changed', =>
      @setState(game: @props.game)
    )

  onGameUpdate: ->
    @setState game: @props.game
    return

  render: ->
    `<div>
      <AlertView game={this.state.game} />
      <PassView game={this.state.game} />
      <PlayersView game={this.state.game} onPlayerAdd={this.onGameUpdate} />
      <BoardView game={this.state.game} onPlay={this.onGameUpdate} />
    </div>`


chatRef = new Firebase("https://intense-fire-8240.firebaseio.com/")
auth = new FirebaseSimpleLogin(chatRef, (error, user) ->
  Go.current_user = user
)


gameId = getParameterByName('g')
unless gameId?
  gameId = "game-#{(new Date).valueOf()}"
  window.location.replace("#{window.location.protocol}//#{window.location.host}/?g=#{gameId}")
  return

console.log gameId
window.game = new Go.Game({ size: 19, game_id: gameId })
game.once 'sync', ->
  React.renderComponent `<ContainerView game={game} />`, document.getElementById("main")
