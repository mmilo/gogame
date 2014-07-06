/** @jsx React.DOM */

var BoardIntersection = React.createClass({
    handleClick: function() {
        if (this.props.board.play(this.props.row, this.props.col))
            this.props.onPlay();
    },
    render: function() {
        var classes = "point ";
        if (this.props.color != Go.EMPTY)
            classes += this.props.color == Go.BLACK ? "stone stone--black" : "stone stone--white";

        return (
            <td onClick={this.handleClick} className={classes}></td>
        );
    }
});

var BoardRow = React.createClass({
  render: function(){
    return (
      <tr className='row'>{this.props.intersections}</tr>
    );
  }
});

var BoardView = React.createClass({
    render: function() {
        var rows = [];
        for (var i = 0; i < this.props.board.size; i++) {
            var intersections = [];
            for (var j = 0; j < this.props.board.size; j++) {
                intersections.push(BoardIntersection({
                    board: this.props.board,
                    color: this.props.board.board[i][j],
                    row: i,
                    col: j,
                    onPlay: this.props.onPlay
                }));
            }
            rows.push(BoardRow({intersections: intersections}));
        }
        var boardClass = 'board turn turn--' + (this.props.board.current_color == Go.BLACK ? 'black' : 'white');
        return (
          <div className='table'>
            <div className={boardClass}>
              <table className='grid'>
                {rows}
              </table>
            </div>
          </div>
        );
    }
});

var AlertView = React.createClass({
    render: function() {
        var text = "";
        if (this.props.board.in_atari)
            text = "ATARI!";
        else if (this.props.board.attempted_suicide)
            text = "SUICIDE!";

        return (
            <div id="alerts">{text}</div>
        );
    }
});

var PassView = React.createClass({
    handleClick: function(e) {
        this.props.board.pass();
    },
    render: function() {
        return (
            <input id="pass-btn" type="button" value="Pass" 
                onClick={this.handleClick} />
        );
    }
});

var ContainerView = React.createClass({
    getInitialState: function() {
        return {'board': this.props.board};
    },
    onBoardUpdate: function() {
        this.setState({"board": this.props.board});
    },
    render: function() {
        return (
            <div>
                <AlertView board={this.state.board} />
                <PassView board={this.state.board} />
                <BoardView board={this.state.board} 
                    onPlay={this.onBoardUpdate.bind(this)} />
            </div>
        )
    }
});

var board = new Go.Board(19);

React.renderComponent(
    <ContainerView board={board} />,
    document.getElementById('main')
);
