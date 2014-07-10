###* @jsx React.DOM ###
BoardIntersection = React.createClass
  handleClick: ->
    @props.onPlay()  if @props.game.play(@props.row, @props.col)
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
    @props.game.pass()
    return

  render: ->
    `<input id="pass-btn" type="button" value="Pass" onClick={this.handleClick} />`

ContainerView = React.createClass

  getInitialState: ->
    { game: @props.game }

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
        <BoardView game={this.state.game} onPlay={this.onGameUpdate.bind(this)} />
    </div>`


gameId = if getParameterByName('g') then getParameterByName('g') else "game-#{(new Date).valueOf()}"
game = new Go.Game({ size: 19, game_id: gameId })
React.renderComponent `<ContainerView game={game} />`, document.getElementById("main")
