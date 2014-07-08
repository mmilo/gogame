###* @jsx React.DOM ###
BoardIntersection = React.createClass
  handleClick: ->
    @props.onPlay()  if @props.board.play(@props.row, @props.col)
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

    while i < @props.board.size
      intersections = []
      j = 0

      while j < @props.board.size
        intersections.push BoardIntersection(
          board: @props.board
          color: @props.board.board[i][j]
          row: i
          col: j
          onPlay: @props.onPlay
        )
        j++
      rows.push BoardRow(intersections: intersections)
      i++
    boardClass = "board turn turn--" + ((if @props.board.current_color is Go.BLACK then "black" else "white"))
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
    if @props.board.in_atari
      text = "ATARI!"
    else if @props.board.attempted_suicide
      text = "SUICIDE!"
    `<div id="alerts">{text}</div>`

PassView = React.createClass
  handleClick: (e) ->
    @props.board.pass()
    return

  render: ->
    `<input id="pass-btn" type="button" value="Pass" onClick={this.handleClick} />`

ContainerView = React.createClass
  getInitialState: ->
    board: @props.board

  onBoardUpdate: ->
    @setState board: @props.board
    return

  render: ->
    `<div>
        <AlertView board={this.state.board} />
        <PassView board={this.state.board} />
        <BoardView board={this.state.board} 
            onPlay={this.onBoardUpdate.bind(this)} />
    </div>`

window.board = board = new Go.Board({ size: 19 })
board.start_game()

React.renderComponent `<ContainerView board={board} />`, document.getElementById("main")
