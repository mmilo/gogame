###* @jsx React.DOM ###
BoardIntersection = React.createClass
  handleClick: ->
    @props.onPlay() if @props.game.play(x: @props.row, y: @props.col)
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

NewGameView = React.createClass
  handleClick: ->
    gameId = new Date().valueOf()
    window.location.replace("#{window.location.protocol}//#{window.location.host}/?g=#{gameId}")
    return
  render: ->
    `<input type="button" value="New Game" onClick={this.handleClick} />`

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
    @props.game.play(pass: true)

  render: ->
    `<input className="btn-pass" type="button" value="Pass" onClick={this.handleClick} />`

UserSessionView = React.createClass
  getInitialState: ->
    signingUp: false
    loggingIn: false

  logout: ->
    auth.logout()
    @setState(loggingIn: false, signingUp: false)

  loginWithTwitter: ->
    auth.login('twitter', {rememberMe: true})

  signupWithEmail: ->
    @setState(signingUp: true, loggingIn: false)

  loginWithEmail: ->
    @setState(loggingIn: true, signingUp: false)

  cancelAction: ->
    @setState(loggingIn: false, signingUp: false)

  render: ->
    if @props.current_user?
      `<div>
        Logged in as: {this.props.current_user.uid}
        <input type="button" value="logout" onClick={this.logout} />
      </div>`
    else if @state.signingUp
      `<SignupAndLoginForm mode='signup' onCancel={this.cancelAction} />`
    else if @state.loggingIn
      `<SignupAndLoginForm mode='login'  onCancel={this.cancelAction} />`
    else
      `<div>
        <input type="button" value="Login with Twitter" onClick={this.loginWithTwitter} />
        <input type="button" value="Login with Email" onClick={this.loginWithEmail} />
        <input type="button" value="Signup with email" onClick={this.signupWithEmail} />
      </div>`

SignupAndLoginForm = React.createClass
  getInitialState: ->
    state = {}
    state.email = if @props.mode is 'signup' then "t-#{new Date().valueOf()}@gamilis.com" else ''
    state.password = ''
    state

  onChange: (e) ->
    state = {}
    state[$(e.target).attr('name')] = $(e.target).val()
    @setState(state)

  submitLogin: (email, password) ->
    auth.login('password', {email: email, password: password, rememberMe: true})

  handleSubmit: ->
    if @props.mode is 'signup'
      auth.createUser @state.email, @state.password, (error, user) =>
        return alert(error) if error
        @submitLogin(@state.email, @state.password)
    else
      @submitLogin(@state.email, @state.password)

  render: ->
    `<div>
      <a href="#" onClick={this.props.onCancel}>cancel</a>
      <input type="email" name="email" value={this.state.email} placeholder='Email address' onChange={this.onChange} />
      <input type="password" name="password" value={this.state.password} placeholder='Password' onChange={this.onChange} />
      <input type="button" value={this.props.mode == 'signup' ? "Sign up" : "Log In"} onClick={this.handleSubmit} />
    </div>`

PlayersView = React.createClass
  getInitialState: ->
    black_player: null
    white_player: null
    current_color: null
    black_player_passed: @props.game.blackPassed()
    white_player_passed: @props.game.whitePassed()
    player_times: @props.game.playerTimes()

  componentWillMount: ->
    @props.game.firebase.child('players').on 'value', (snapshot) =>
      players = snapshot.val() || {}
      @setState
        black_player: players[Go.BLACK]
        white_player: players[Go.WHITE]
        current_color: @props.game.current_color()

    @props.game.on 'board_state_changed', =>
      @setState
        current_color: @props.game.current_color()
        black_player_passed: @props.game.blackPassed()
        white_player_passed: @props.game.whitePassed()
        player_times: @props.game.playerTimes()
    # Update the game clock
    setInterval =>
      @setState
        player_times: @props.game.playerTimes()
    , 1000

  handleClick: ->
    if @props.current_user?
      @props.game.join(@props.current_user.uid)
    else
      return alert('You must log in to join the game')

  render: ->
    classes = "players turn--" + @state.current_color
    show_pass_for_black = @state.current_color is Go.BLACK and @props.current_user?.uid is @state.black_player
    show_pass_for_white = @state.current_color is Go.WHITE and @props.current_user?.uid is @state.white_player
    `<div className={classes}>
      <ul>
        <li className={this.state.black_player ? '' : 'waiting'}>
          <div className='stone stone--black'></div>
          {this.state.black_player ? this.state.black_player : 'waiting for player 1 to join...'}
          {this.state.black_player_passed ? " ---  [ PASSED ]" : ''}
          {show_pass_for_black ? <PassView game={this.props.game} /> : null }
          <br />
          {Math.round(this.state.player_times[Go.BLACK] / 1000) } seconds
        </li>
        <li className={this.state.white_player ? '' : 'waiting'}>
          <div className='stone stone--white'></div>
          {this.state.white_player ? this.state.white_player : 'waiting for player 2 to join...'}
          {this.state.white_player_passed ? " --- [ PASSED ]" : ''}
          {show_pass_for_white ? <PassView game={this.props.game} /> : null }
          <br />
          {Math.round(this.state.player_times[Go.WHITE] / 1000) } seconds
        </li>
      </ul>
      {!this.state.black_player || !this.state.white_player ? <input id="join-btn" type="button" value="Join" onClick={this.handleClick} /> : ''}
    </div>
    `


ContainerView = React.createClass
  getInitialState: ->
    game: @props.game
    current_user: @props.environment.current_user

  componentWillMount: ->
    @props.game.firebase.child('moves').on 'value', =>
      @setState(game: @props.game)
    @props.environment.on 'change:current_user', =>
      @setState(current_user: @props.environment.current_user)

  onGameUpdate: ->
    @setState game: @props.game
    return

  render: ->
    `<div>
      <div className='user-session'>
        <UserSessionView current_user={this.state.current_user} />
      </div>
      <div className="game-controls">
        <NewGameView />
        <AlertView game={this.state.game} />
        <PlayersView game={this.state.game} current_user={this.state.current_user} />
      </div>
      <div className="game-board">
        <BoardView game={this.state.game} onPlay={this.onGameUpdate} />
      </div>
    </div>`


chatRef = new Firebase("https://intense-fire-8240.firebaseio.com/")
auth = new FirebaseSimpleLogin(chatRef, (error, user) ->
  Go.current_user = user
  Go.trigger('change:current_user')
)


if (gameId = getParameterByName('g'))?
  window.game = new Go.Game({ size: 19, game_id: gameId })
  game.once 'ready', ->
    React.renderComponent `<ContainerView game={game} environment={Go} />`, document.getElementById("main")
else
  React.renderComponent `<NewGameView />`, document.getElementById("main")

