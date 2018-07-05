/**
 * pageTitle - Directive for set Page title - mata title
 */
function pageTitle($rootScope, $timeout) {
    return {
        link: function(scope, element) {
            var listener = function(event, toState, toParams, fromState, fromParams) {
                // Default title - load on Dashboard 1
                var title = 'Intel Retail Workshop';
                // Create your own title pattern
                if (toState.data && toState.data.pageTitle) title = 'Intel Retail Workshop | ' + toState.data.pageTitle;
                $timeout(function() {
                    element.text(title);
                });
            };
            $rootScope.$on('$stateChangeStart', listener);
        }
    };
}

/**
 * sideNavigation - Directive for run metsiMenu on sidebar navigation
 */
function sideNavigation($timeout) {
    return {
        restrict: 'A',
        link: function(scope, element) {
            // Call the metsiMenu plugin and plug it to sidebar navigation
            $timeout(function(){
                element.metisMenu();
            });
        }
    };
}

/**
 * checkbox - Directive for the fancy, dancy checkbox
 */
function checkbox($timeout) {
  return {
    restrict: 'E',
    transclude: true,
    scope: {
      message: '@',
      image: '@'
    },
    templateUrl: 'views/common/checkbox.html',
    controller: function ($scope, $element) {
      $scope.toggleCheckMark = function () {
        var checkbox = $element.find('div.Checkbox');
        var ibox = $element.closest('section');
        ibox.toggleClass('checkboxFade');
        checkbox.toggleClass('marked');
      };
    }
  };
}

/**
 * ibox -
 */
function ibox($timeout) {
  return {
    restrict: 'AE',
    transclude: true,
    replace: true,
    scope: {
      title: '@',
      collapse: '@'
    },
    templateUrl: 'views/common/ibox.html',
    controller: function ($scope, $element) {
      // Function for collapse ibox
      $scope.showhide = function () {
        var ibox = $element.closest('div.ibox');
        var icon = $element.find('i:first');
        var content = ibox.find('div.ibox-content');
        content.slideToggle(200);
        // Toggle icon from up to down
        icon.toggleClass('fa-chevron-up').toggleClass('fa-chevron-down');
        ibox.toggleClass('').toggleClass('border-bottom');
        $timeout(function () {
          ibox.resize();
          ibox.find('[id^=map-]').resize();
        }, 50);
      },
      // Function for close ibox
      $scope.closebox = function () {
        var ibox = $element.closest('div.ibox');
        ibox.remove();
      }
    }
  };
};

/**
 * contentBlock -
 */
function contentBlock($timeout) {
  return {
    restrict: 'AE',
    transclude: true,
    replace: true,
    scope: {
      name: '@',
      message: '@',
      imageLink: '@',
      slidesLink: '@'
    },
    templateUrl: 'views/common/contentBlock.html',
    controller: function ($scope, $element) {
    }
  };
};


/**
 * iboxTools - Directive for iBox tools elements in right corner of ibox
 */
function labels($timeout) {
  return {
    restrict: 'E',
    scope: true,
    templateUrl: 'views/common/labels.html',
    link: function(scope, element, attrs){
      scope.arduino = 'arduino' in attrs;
      scope.gateway = 'gateway' in attrs;
      scope.xdk = 'xdk' in attrs;
      scope.nodered = 'nodered' in attrs;
      scope.windows = 'windows' in attrs;
      scope.laptop = 'laptop' in attrs;
        scope.nuc = 'nuc' in attrs;
      scope.apple = 'apple' in attrs;
      scope.linux = 'linux' in attrs;
    }
  };
};

/**
 * iboxTools - Directive for iBox tools elements in right corner of ibox
 */
function iboxTools($timeout) {
    return {
        restrict: 'A',
        scope: true,
        templateUrl: 'views/common/ibox_tools.html',
        controller: function ($scope, $element) {
          // Function for close ibox
          $scope.closebox = function () {
            var ibox = $element.closest('div.ibox');
            ibox.remove();
          }
        }
    };
}

/**
 * minimalizaSidebar - Directive for minimalize sidebar
 */
function minimalizaSidebar($timeout) {
    return {
        restrict: 'A',
        template: '<a class="navbar-minimalize minimalize-styl-2 btn btn-primary " href="" ng-click="minimalize()"><i class="fa fa-arrow-left"></i></a>',
        controller: function ($scope, $element) {
            $scope.minimalize = function () {
                $("body").toggleClass("mini-navbar");
                if (!$('body').hasClass('mini-navbar') || $('body').hasClass('body-small')) {
                    // Hide menu in order to smoothly turn on when maximize menu
                    $('#side-menu').hide();
                    // For smoothly turn on menu
                    setTimeout(
                        function () {
                            $('#side-menu').fadeIn(400);
                        }, 200);
                } else if ($('body').hasClass('fixed-sidebar')){
                    $('#side-menu').hide();
                    setTimeout(
                        function () {
                            $('#side-menu').fadeIn(400);
                        }, 100);
                } else {
                    // Remove all inline style from jquery fadeIn function to reset menu state
                    $('#side-menu').removeAttr('style');
                }
            }
        }
    };
};

/**
 * iboxTools with full screen - Directive for iBox tools elements in right corner of ibox with full screen option
 */
function iboxToolsFullScreen($timeout) {
    return {
        restrict: 'A',
        scope: true,
        templateUrl: 'views/common/ibox_tools_full_screen.html',
        controller: function ($scope, $element) {
            // Function for collapse ibox
            $scope.showhide = function () {
                var ibox = $element.closest('div.ibox');
                var icon = $element.find('i:first');
                var content = ibox.find('div.ibox-content');
                content.slideToggle(200);
                // Toggle icon from up to down
                icon.toggleClass('fa-chevron-up').toggleClass('fa-chevron-down');
                ibox.toggleClass('').toggleClass('border-bottom');
                $timeout(function () {
                    ibox.resize();
                    ibox.find('[id^=map-]').resize();
                }, 50);
            };
            // Function for close ibox
            $scope.closebox = function () {
                var ibox = $element.closest('div.ibox');
                ibox.remove();
            };
            // Function for full screen
            $scope.fullscreen = function () {
                var ibox = $element.closest('div.ibox');
                var button = $element.find('i.fa-expand');
                $('body').toggleClass('fullscreen-ibox-mode');
                button.toggleClass('fa-expand').toggleClass('fa-compress');
                ibox.toggleClass('fullscreen');
                setTimeout(function() {
                    $(window).trigger('resize');
                }, 100);
            }
        }
    };
}



/**
 *
 * Pass all functions into module
 */
angular
  .module('labs')
  .directive('pageTitle', pageTitle)
  .directive('labels', labels)
  .directive('ibox', ibox)
  .directive('sideNavigation', sideNavigation)
  .directive('iboxTools', iboxTools)
  .directive('checkbox', checkbox)
  .directive('contentBlock', contentBlock)
  .directive('minimalizaSidebar', minimalizaSidebar)
  .directive('iboxToolsFullScreen', iboxToolsFullScreen);
