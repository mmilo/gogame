###* @jsx React.DOM ###

window.ChatView = React.createClass
  getInitialState: ->
    return { comments: [], users: {} }

  componentWillMount: ->
    @comments = []
    @chatRef = @props.firebase.child('comments').child(@props.game_id)
    @chatRef.on 'child_added', (snap) =>
      comment = snap.val()
      if comment.uid and !@state.users[comment.uid]?
        @observePlayer(comment.uid)
      @comments.push(snap.val())
      @setState(comments: @comments)

  observePlayer: (uid) ->
    @props.firebase.child('users').child(uid).on 'value', (snap) =>
      users = @state.users
      users[uid] = snap.val()
      @setState(users: users)

  addComment: (e) ->
    if e.which is 13
      message = e.currentTarget.value
      return false if message is ''
      node = @chatRef.push(uid: Go.current_user.uid, text: message)
      # Clear the input
      e.currentTarget.value = ''

  render: (flag) ->
    `<div className="game-chat">
        <CommentsList users={this.state.users} comments={this.state.comments} />
        <input type="text" onKeyPress={this.addComment} value={this.state.currentMessage} placeholder="Press enter to send..." />
      </div>
    `


window.CommentsList = React.createClass
  componentWillMount: ->
    @shouldScrollBottom = true
  render: ->
    comments = @props.comments.map (comment, index) =>
      name = @props.users[comment.uid]?.displayName || 'unknown'
      `<li><b>{name}:</b> <span>{comment.text}</span></li>`

    `<ul className="game-comments">
      {comments}
    </ul>`

  componentWillUpdate: ->
    node = @getDOMNode()
    @shouldScrollBottom = node.scrollTop + node.offsetHeight >= node.scrollHeight
   
  componentDidUpdate: ->
    if @shouldScrollBottom
      node = @getDOMNode()
      node.scrollTop = node.scrollHeight
