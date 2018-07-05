/**
 * MainCtrl - controller
 */
function MainCtrl() {
}


/**
* codeEditorCtrl - Controller for code editor - Code Mirror
*/
function CodeEditorCtrl($scope) {
  $scope.editorOptions = {
    lineNumbers: true,
    matchBrackets: true,
    styleActiveLine: true,
    theme:"ambiance"
  };
}


angular
  .module('labs')
  .controller('MainCtrl', MainCtrl)
  .controller('CodeEditorCtrl', ['$scope', CodeEditorCtrl]);
