window.Go = {
  EMPTY: 0
  BLACK: 'black'
  WHITE: 'white'
  STATUS: {
    OPEN: 0
    WAITING: 1
    FULL: 2
    ENDED: 3
  }
}
_.extend(Go, Backbone.Events)
