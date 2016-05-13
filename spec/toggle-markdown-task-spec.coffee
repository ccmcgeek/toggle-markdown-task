describe "toggling markdown task", ->
  [activationPromise, editor, editorView] = []

  toggleMarkdownTask = (callback) ->
    atom.commands.dispatch editorView, "toggle-markdown-task:toggle"
    waitsForPromise -> activationPromise
    runs(callback)

  beforeEach ->
    waitsForPromise ->
      atom.workspace.open()

    runs ->
      editor = atom.workspace.getActiveTextEditor()
      editorView = atom.views.getView(editor)
      activationPromise = atom.packages.activatePackage("toggle-markdown-task")

  describe "when the cursor is on a single line", ->
    it "toggles a task from incomplete to complete", ->
      editor.setText """
        - [ ] A
        - [ ] B
        - [ ] C
      """
      editor.setCursorBufferPosition([1, 0])

      toggleMarkdownTask ->
        expect(editor.getText()).toBe """
          - [ ] A
          - [x] B
          - [ ] C
        """

    it "toggles a task from complete to incomplete", ->
      editor.setText """
        - [ ] A
        - [x] B
        - [ ] C
      """
      editor.setCursorBufferPosition([1, 0])

      toggleMarkdownTask ->
        expect(editor.getText()).toBe """
          - [ ] A
          - [ ] B
          - [ ] C
        """

    it "retains the original cursor position", ->
      editor.setText """
        - [ ] A
        - [ ] B
        - [ ] C
      """
      editor.setCursorBufferPosition([1, 2])

      toggleMarkdownTask ->
        expect(editor.getCursorBufferPosition()).toEqual [1, 2]

  describe "when multiple lines are selected", ->
    it "toggles completion of the tasks on the selected lines", ->
      editor.setText """
        - [ ] A
        - [ ] B
        - [ ] C
        - [ ] D
      """
      editor.setSelectedBufferRange([[1,1], [2,1]])

      toggleMarkdownTask ->
        expect(editor.getText()).toBe """
          - [ ] A
          - [x] B
          - [x] C
          - [ ] D
        """

    it "retains the original selection range", ->
      editor.setText """
        - [ ] A
        - [ ] B
        - [ ] C
        - [ ] D
      """
      editor.setSelectedBufferRange([[1,1], [2,1]])

      toggleMarkdownTask ->
        expect(editor.getSelectedBufferRange()).toEqual [[1,1], [2,1]]

  describe "when multiple cursors are present", ->
    it "toggles completion of the tasks in every cursor's selection range", ->
      editor.setText """
        - [ ] A
        - [ ] B
        - [ ] C
        - [ ] D
      """

      # Add cursor with empty selection range on the line of task "A"
      editor.addCursorAtBufferPosition([0, 0])

      # Add cursor with selection range that includes tasks "C" and "D"
      editor.addSelectionForBufferRange([[2, 0], [3, 7]])

      toggleMarkdownTask ->
        expect(editor.getText()).toBe """
          - [x] A
          - [ ] B
          - [x] C
          - [x] D
        """

  describe "when markdown formatting varies", ->
    it "retains the original spaces and tabs around the checkbox",->
      editor.setText """
        - [ ] A space
        -   [ ]    B spaces
        -\u0009[ ]\u0009C tab
        -\u0009\u0009\u0009[ ]\u0009\u0009D tabs
        -\u0009 \u0009\u0009 [ ] \u0009 \u0009E mix
          - [x] F space
          -   [x]    G spaces
          -\u0009[x]\u0009H tab
          -\u0009\u0009\u0009[x]\u0009\u0009I tabs
          -\u0009 \u0009\u0009 [x] \u0009 \u0009J mix
      """
      editor.setSelectedBufferRange([[0,1],[9,1]])

      toggleMarkdownTask ->
        expect(editor.getText()).toBe """
          - [x] A space
          -   [x]    B spaces
          -\u0009[x]\u0009C tab
          -\u0009\u0009\u0009[x]\u0009\u0009D tabs
          -\u0009 \u0009\u0009 [x] \u0009 \u0009E mix
            - [ ] F space
            -   [ ]    G spaces
            -\u0009[ ]\u0009H tab
            -\u0009\u0009\u0009[ ]\u0009\u0009I tabs
            -\u0009 \u0009\u0009 [ ] \u0009 \u0009J mix
        """

    it "retains the original list bullet character",->
      editor.setText """
        - [ ] A
        + [ ] B
        * [ ] C
        - [x] D
        + [x] E
        * [x] F
      """
      editor.setSelectedBufferRange([[0,1],[5,1]])

      toggleMarkdownTask ->
        expect(editor.getText()).toBe """
          - [x] A
          + [x] B
          * [x] C
          - [ ] D
          + [ ] E
          * [ ] F
        """

    it "checks any single whitespace checkbox",->
      editor.setText """
        - [ ] A space
        - [\u0009] B tab
        - [\u00a0] C non-breaking space
      """
      editor.setSelectedBufferRange([[0,1],[2,1]])

      toggleMarkdownTask ->
        expect(editor.getText()).toBe """
          - [x] A space
          - [x] B tab
          - [x] C non-breaking space
        """

    it "unchecks upper and lowercase Xs",->
      editor.setText """
        - [x] A
        - [X] B
      """
      editor.setSelectedBufferRange([[0,1],[2,1]])

      toggleMarkdownTask ->
        expect(editor.getText()).toBe """
          - [ ] A
          - [ ] B
        """
