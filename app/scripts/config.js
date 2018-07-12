function config($stateProvider, $urlRouterProvider, $ocLazyLoadProvider) {
  $urlRouterProvider.otherwise("/index/home");

  $ocLazyLoadProvider.config({
    debug: false
  });

  $stateProvider
    .state('index', {
      abstract: true,
      url: "/index",
      templateUrl: "views/common/content.html",
    })
    .state('index.home', {
      url: "/home",
      templateUrl: "views/home.html",
      data: {
        pageTitle: 'Home',
        specialClass: 'landing-page'
      }
    })
    .state('index.schedule', {
      url: "/schedule",
      templateUrl: "views/schedule.html",
      data: {
        pageTitle: 'Schedule'
      }
    })
    .state('index.presentations', {
      url: "/presentations",
      templateUrl: "views/presentations.html",
      data: {
        pageTitle: 'Slides View'
      }
    })
  /*  .state('index.videos', {
      url: "/videos",
      templateUrl: "views/videos.html",
      data: {
        pageTitle: 'Videos'
      }
    }) */
    .state('labs', {
      abstract: true,
      url: "/labs",
      templateUrl: "views/common/content.html"
    })
    .state('labs.setup-development-environment', {
      url: "/setup-development-environment",
      templateUrl: "views/labs/setup-development-environment/index.html",
      data: {
        pageTitle: ''
      }
    })
    .state('labs.laboverview', {
      url: "/laboverview",
      templateUrl: "views/labs/laboverview/index.html",
      data: {
        pageTitle: 'Lab Overview'
      },
      resolve: {
        loadPlugin: function($ocLazyLoad) {
          return $ocLazyLoad.load([{
            serie: true,
            files: [
              'bower_components/codemirror/lib/codemirror.css',
              'bower_components/codemirror/theme/ambiance.css',
              'bower_components/codemirror/lib/codemirror.js',
              'bower_components/codemirror/mode/javascript/javascript.js'
            ]
          }, {
            name: 'ui.codemirror',
            files: ['bower_components/angular-ui-codemirror/ui-codemirror.min.js']
          }]);
        }
      }
    })
    .state('labs.labInfrastructure', {
      url: "/laboverview",
      templateUrl: "views/labs/labInfrastructure/index.html",
      data: {
        pageTitle: 'Lab Infrastructure'
      },
      resolve: {
        loadPlugin: function($ocLazyLoad) {
          return $ocLazyLoad.load([{
            serie: true,
            files: [
              'bower_components/codemirror/lib/codemirror.css',
              'bower_components/codemirror/theme/ambiance.css',
              'bower_components/codemirror/lib/codemirror.js',
              'bower_components/codemirror/mode/javascript/javascript.js'
            ]
          }, {
            name: 'ui.codemirror',
            files: ['bower_components/angular-ui-codemirror/ui-codemirror.min.js']
          }]);
        }
      }
    })
    .state('labs.videoperformance-maarssetup', {
      url: "/videoperformance-maarssetup",
      templateUrl: "views/labs/videoperformance-maarssetup/index.html",
      data: {
        pageTitle: 'MAARS Source Setup'
      },
      resolve: {
        loadPlugin: function($ocLazyLoad) {
          return $ocLazyLoad.load([{
            serie: true,
            files: [
              'bower_components/codemirror/lib/codemirror.css',
              'bower_components/codemirror/theme/ambiance.css',
              'bower_components/codemirror/lib/codemirror.js',
              'bower_components/codemirror/mode/javascript/javascript.js'
            ]
          }, {
            name: 'ui.codemirror',
            files: ['bower_components/angular-ui-codemirror/ui-codemirror.min.js']
          }]);
        }
      }
    })
    .state('labs.videoperformance-marsunderstand', {
      url: "/videoperformance-marsunderstand",
      templateUrl: "views/labs/videoperformance-marsunderstand/index.html",
      data: {
        pageTitle: 'MARS Application Walkthrough'
      },
      resolve: {
        loadPlugin: function($ocLazyLoad) {
          return $ocLazyLoad.load([{
            serie: true,
            files: [
              'bower_components/codemirror/lib/codemirror.css',
              'bower_components/codemirror/theme/ambiance.css',
              'bower_components/codemirror/lib/codemirror.js',
              'bower_components/codemirror/mode/javascript/javascript.js'
            ]
          }, {
            name: 'ui.codemirror',
            files: ['bower_components/angular-ui-codemirror/ui-codemirror.min.js']
          }]);
        }
      }
    })
    .state('labs.videoperformance-maarscustomize', {
      url: "/videoperformance-maarsunderstand",
      templateUrl: "views/labs/videoperformance-maarscustomize/index.html",
      data: {
        pageTitle: 'MAARS Customize'
      },
      resolve: {
        loadPlugin: function($ocLazyLoad) {
          return $ocLazyLoad.load([{
            serie: true,
            files: [
              'bower_components/codemirror/lib/codemirror.css',
              'bower_components/codemirror/theme/ambiance.css',
              'bower_components/codemirror/lib/codemirror.js',
              'bower_components/codemirror/mode/javascript/javascript.js'
            ]
          }, {
            name: 'ui.codemirror',
            files: ['bower_components/angular-ui-codemirror/ui-codemirror.min.js']
          }]);
        }
      }
    })

    .state('labs.videoperformance-maarscustomsoln', {
      url: "/videoperformance-maarscustomsoln",
      templateUrl: "views/labs/videoperformance-maarscustomsoln/index.html",
      data: {
        pageTitle: 'Integrate MAARs into custom solution'
      },
      resolve: {
        loadPlugin: function($ocLazyLoad) {
          return $ocLazyLoad.load([{
            serie: true,
            files: [
              'bower_components/codemirror/lib/codemirror.css',
              'bower_components/codemirror/theme/ambiance.css',
              'bower_components/codemirror/lib/codemirror.js',
              'bower_components/codemirror/mode/javascript/javascript.js'
            ]
          }, {
            name: 'ui.codemirror',
            files: ['bower_components/angular-ui-codemirror/ui-codemirror.min.js']
          }]);
        }
      }
    })

    .state('labs.videoperformance-mediasdk', {
      url: "/videoperformance-mediasdk",
      templateUrl: "views/labs/videoperformance-mediasdk/index.html",
      data: {
        pageTitle: 'Explore Intel Media SDK'
      },
      resolve: {
        loadPlugin: function($ocLazyLoad) {
          return $ocLazyLoad.load([{
            serie: true,
            files: [
              'bower_components/codemirror/lib/codemirror.css',
              'bower_components/codemirror/theme/ambiance.css',
              'bower_components/codemirror/lib/codemirror.js',
              'bower_components/codemirror/mode/javascript/javascript.js'
            ]
          }, {
            name: 'ui.codemirror',
            files: ['bower_components/angular-ui-codemirror/ui-codemirror.min.js']
          }]);
        }
      }
    })

    .state('labs.videoperformance-mediasdksamples', {
      url: "/videoperformance-mediasdksamples",
      templateUrl: "views/labs/videoperformance-mediasdksamples/index.html",
      data: {
        pageTitle: 'Understand Media Acceleration Reference Software'
      },
      resolve: {
        loadPlugin: function($ocLazyLoad) {
          return $ocLazyLoad.load([{
            serie: true,
            files: [
              'bower_components/codemirror/lib/codemirror.css',
              'bower_components/codemirror/theme/ambiance.css',
              'bower_components/codemirror/lib/codemirror.js',
              'bower_components/codemirror/mode/javascript/javascript.js'
            ]
          }, {
            name: 'ui.codemirror',
            files: ['bower_components/angular-ui-codemirror/ui-codemirror.min.js']
          }]);
        }
      }
    })

    .state('labs.remote-configamt', {
      url: "/remote-configamt",
      templateUrl: "views/labs/remote-configamt/index.html",
      data: {
        pageTitle: 'Configure AMT'
      },
      resolve: {
        loadPlugin: function($ocLazyLoad) {
          return $ocLazyLoad.load([{
            serie: true,
            files: [
              'bower_components/codemirror/lib/codemirror.css',
              'bower_components/codemirror/theme/ambiance.css',
              'bower_components/codemirror/lib/codemirror.js',
              'bower_components/codemirror/mode/javascript/javascript.js'
            ]
          }, {
            name: 'ui.codemirror',
            files: ['bower_components/angular-ui-codemirror/ui-codemirror.min.js']
          }]);
        }
      }
    })

    .state('labs.remote-configintelmc', {
      url: "/remote-configintelmc",
      templateUrl: "views/labs/remote-configintelmc/index.html",
      data: {
        pageTitle: 'Manage remote systems'
      },
      resolve: {
        loadPlugin: function($ocLazyLoad) {
          return $ocLazyLoad.load([{
            serie: true,
            files: [
              'bower_components/codemirror/lib/codemirror.css',
              'bower_components/codemirror/theme/ambiance.css',
              'bower_components/codemirror/lib/codemirror.js',
              'bower_components/codemirror/mode/javascript/javascript.js'
            ]
          }, {
            name: 'ui.codemirror',
            files: ['bower_components/angular-ui-codemirror/ui-codemirror.min.js']
          }]);
        }
      }
    })
    .state('labs.remote-configmeshcentral', {
      url: "/remote-configmeshcentral",
      templateUrl: "views/labs/remote-configmeshcentral/index.html",
      data: {
        pageTitle: 'Manage remote systems using opensource cloud'
      },
    resolve: {
      loadPlugin: function($ocLazyLoad) {
        return $ocLazyLoad.load([{
          serie: true,
          files: [
            'bower_components/codemirror/lib/codemirror.css',
            'bower_components/codemirror/theme/ambiance.css',
            'bower_components/codemirror/lib/codemirror.js',
            'bower_components/codemirror/mode/javascript/javascript.js'
          ]
        }, {
          name: 'ui.codemirror',
          files: ['bower_components/angular-ui-codemirror/ui-codemirror.min.js']
        }]);
      }
    }
  })


.state('labs.analytics-exploreopenvinosamples', {
    url: "/labs.analytics-exploreopenvinosamples",
    templateUrl: "views/labs/analytics-exploreopenvinosamples/index.html",
    data: {
        pageTitle: 'Simple Examples using OpenVINO'
    },
    resolve: {
        loadPlugin: function ($ocLazyLoad) {
            return $ocLazyLoad.load([{
                serie: true,
                files: [
                  'bower_components/codemirror/lib/codemirror.css',
                  'bower_components/codemirror/theme/ambiance.css',
                  'bower_components/codemirror/lib/codemirror.js',
                  'bower_components/codemirror/mode/javascript/javascript.js'
                ]
            }, {
                name: 'ui.codemirror',
                files: ['bower_components/angular-ui-codemirror/ui-codemirror.min.js']
            }]);
        }
    }
})


  .state('labs.analytics-openvinoface', {
    url: "/analytics-openvinoface",
    templateUrl: "views/labs/analytics-openvinoface/index.html",
    data: {
      pageTitle: 'Face detection using OpenVINO'
    },
    resolve: {
      loadPlugin: function($ocLazyLoad) {
        return $ocLazyLoad.load([{
          serie: true,
          files: [
            'bower_components/codemirror/lib/codemirror.css',
            'bower_components/codemirror/theme/ambiance.css',
            'bower_components/codemirror/lib/codemirror.js',
            'bower_components/codemirror/mode/javascript/javascript.js'
          ]
        }, {
          name: 'ui.codemirror',
          files: ['bower_components/angular-ui-codemirror/ui-codemirror.min.js']
        }]);
      }
    }
})
.state('labs.analytics-openvinoagegenderdetection', {
  url: "/analytics-openvinoagegenderdetection",
  templateUrl: "views/labs/analytics-openvinoagegenderdetection/index.html",
  data: {
    pageTitle: 'Age and Gender detection with OpenVINO'
  },
  resolve: {
    loadPlugin: function($ocLazyLoad) {
      return $ocLazyLoad.load([{
        serie: true,
        files: [
          'bower_components/codemirror/lib/codemirror.css',
          'bower_components/codemirror/theme/ambiance.css',
          'bower_components/codemirror/lib/codemirror.js',
          'bower_components/codemirror/mode/javascript/javascript.js'
        ]
      }, {
        name: 'ui.codemirror',
        files: ['bower_components/angular-ui-codemirror/ui-codemirror.min.js']
      }]);
    }
  }
})

.state('labs.analytics-analyse', {
  url: "/analytics-analyse",
  templateUrl: "views/labs/analytics-analyse/index.html",
  data: {
    pageTitle: 'Analyse face data'
  },
  resolve: {
    loadPlugin: function($ocLazyLoad) {
      return $ocLazyLoad.load([{
        serie: true,
        files: [
          'bower_components/codemirror/lib/codemirror.css',
          'bower_components/codemirror/theme/ambiance.css',
          'bower_components/codemirror/lib/codemirror.js',
          'bower_components/codemirror/mode/javascript/javascript.js'
        ]
      }, {
        name: 'ui.codemirror',
        files: ['bower_components/angular-ui-codemirror/ui-codemirror.min.js']
      }]);
    }
  }
})
.state('labs.security-systemd', {
  url: "/security-systemd",
  templateUrl: "views/labs/security-systemd/index.html",
  data: {
    pageTitle: 'Systemd'
  },
  resolve: {
    loadPlugin: function($ocLazyLoad) {
      return $ocLazyLoad.load([{
        serie: true,
        files: [
          'bower_components/codemirror/lib/codemirror.css',
          'bower_components/codemirror/theme/ambiance.css',
          'bower_components/codemirror/lib/codemirror.js',
          'bower_components/codemirror/mode/javascript/javascript.js'
        ]
      }, {
        name: 'ui.codemirror',
        files: ['bower_components/angular-ui-codemirror/ui-codemirror.min.js']
      }]);
    }
  }
})
  .state('labs.sensors-c', {
    url: "/sensors-c",
    templateUrl: "views/labs/sensors-c/index.html",
    data: {
      pageTitle: 'Build an Edge Device'
    },
    resolve: {
      loadPlugin: function($ocLazyLoad) {
        return $ocLazyLoad.load([{
          serie: true,
          files: [
            'bower_components/codemirror/lib/codemirror.css',
            'bower_components/codemirror/theme/ambiance.css',
            'bower_components/codemirror/lib/codemirror.js',
            'bower_components/codemirror/mode/javascript/javascript.js'
          ]
        }, {
          name: 'ui.codemirror',
          files: ['bower_components/angular-ui-codemirror/ui-codemirror.min.js']
        }]);
      }
    }
  })
  .state('labs.sensors-javascript', {
      url: "/sensors-javascript",
      templateUrl: "views/labs/sensors-javascript/index.html",
      data: {
        pageTitle: 'Build an Edge Device'
      },
      resolve: {
        loadPlugin: function($ocLazyLoad) {
          return $ocLazyLoad.load([{
            serie: true,
            files: [
              'bower_components/codemirror/lib/codemirror.css',
              'bower_components/codemirror/theme/ambiance.css',
              'bower_components/codemirror/lib/codemirror.js',
              'bower_components/codemirror/mode/javascript/javascript.js'
            ]
          }, {
            name: 'ui.codemirror',
            files: ['bower_components/angular-ui-codemirror/ui-codemirror.min.js']
          }]);
        }
      }
    })  .state('labs.sensors-java', {
        url: "/sensors-java",
        templateUrl: "views/labs/sensors-java/index.html",
        data: {
          pageTitle: 'Build an Edge Device'
        },
        resolve: {
          loadPlugin: function($ocLazyLoad) {
            return $ocLazyLoad.load([{
              serie: true,
              files: [
                'bower_components/codemirror/lib/codemirror.css',
                'bower_components/codemirror/theme/ambiance.css',
                'bower_components/codemirror/lib/codemirror.js',
                'bower_components/codemirror/mode/javascript/javascript.js'
              ]
            }, {
              name: 'ui.codemirror',
              files: ['bower_components/angular-ui-codemirror/ui-codemirror.min.js']
            }]);
          }
        }
      })
      .state('labs.sensors-node-red', {
        url: "/sensors-node-red",
        templateUrl: "views/labs/sensors-node-red/index.html",
        data: {
          pageTitle: 'Build an Edge Device'
        },
        resolve: {
          loadPlugin: function($ocLazyLoad) {
            return $ocLazyLoad.load([{
              serie: true,
              files: [
                'bower_components/codemirror/lib/codemirror.css',
                'bower_components/codemirror/theme/ambiance.css',
                'bower_components/codemirror/lib/codemirror.js',
                'bower_components/codemirror/mode/javascript/javascript.js'
              ]
            }, {
              name: 'ui.codemirror',
              files: ['bower_components/angular-ui-codemirror/ui-codemirror.min.js']
            }]);
          }
        }
      })

    .state('labs.cloud', {
      url: "/cloud",
      templateUrl: "views/labs/cloud/index.html",
      data: {
        pageTitle: 'Data Analytics on the Cloud'
      },
      resolve: {
        loadPlugin: function($ocLazyLoad) {
          return $ocLazyLoad.load([{
            serie: true,
            files: [
              'bower_components/codemirror/lib/codemirror.css',
              'bower_components/codemirror/theme/ambiance.css',
              'bower_components/codemirror/lib/codemirror.js',
              'bower_components/codemirror/mode/javascript/javascript.js'
            ]
          }, {
            name: 'ui.codemirror',
            files: ['bower_components/angular-ui-codemirror/ui-codemirror.min.js']
          }]);
        }
      }
    })
    .state('labs.dev-hub', {
      url: "/dev-hub",
      templateUrl: "views/labs/dev-hub/index.html",
      data: {
        pageTitle: 'Intel IoT Gateway Developer Hub'
      },
      resolve: {
        loadPlugin: function($ocLazyLoad) {
          return $ocLazyLoad.load([{
            serie: true,
            files: [
              'bower_components/codemirror/lib/codemirror.css',
              'bower_components/codemirror/theme/ambiance.css',
              'bower_components/codemirror/lib/codemirror.js',
              'bower_components/codemirror/mode/javascript/javascript.js'
            ]
          }, {
            name: 'ui.codemirror',
            files: ['bower_components/angular-ui-codemirror/ui-codemirror.min.js']
          }]);
        }
      }
    })
    .state('labs.solutions', {
      url: "/solutions",
      templateUrl: "views/solutions.html",
      data: {
        pageTitle: 'Lab Solutions'
      }
    })
    .state('labs.additional-info-mqtt', {
      url: "/additional-info-mqtt",
      templateUrl: "views/labs/additional-info-mqtt/index.html",
      data: {
        pageTitle: 'Additional Information: Debugging MQTT'
      },
      resolve: {
        loadPlugin: function($ocLazyLoad) {
          return $ocLazyLoad.load([{
            serie: true,
            files: [
              'bower_components/codemirror/lib/codemirror.css',
              'bower_components/codemirror/theme/ambiance.css',
              'bower_components/codemirror/lib/codemirror.js',
              'bower_components/codemirror/mode/javascript/javascript.js'
            ]
          }, {
            name: 'ui.codemirror',
            files: ['bower_components/angular-ui-codemirror/ui-codemirror.min.js']
          }]);
        }
      }
    })
    .state('labs.additional-info-virtual-sensor', {
      url: "/additional-info-virtual-sensor",
      templateUrl: "views/labs/additional-info-virtual-sensor/index.html",
      data: {
        pageTitle: 'Additional Information: Virtual Sensor'
      },
      resolve: {
        loadPlugin: function($ocLazyLoad) {
          return $ocLazyLoad.load([{
            serie: true,
            files: [
              'bower_components/codemirror/lib/codemirror.css',
              'bower_components/codemirror/theme/ambiance.css',
              'bower_components/codemirror/lib/codemirror.js',
              'bower_components/codemirror/mode/javascript/javascript.js'
            ]
          }, {
            name: 'ui.codemirror',
            files: ['bower_components/angular-ui-codemirror/ui-codemirror.min.js']
          }]);
        }
      }
    })
    .state('labs.additional-info-mongodb-schemas', {
      url: "/additional-info-mongodb-schemas",
      templateUrl: "views/labs/additional-info-mongodb-schemas/index.html",
      data: {
        pageTitle: 'Additional Information: Mongoose Schemas'
      },
      resolve: {
        loadPlugin: function($ocLazyLoad) {
          return $ocLazyLoad.load([{
            serie: true,
            files: [
              'bower_components/codemirror/lib/codemirror.css',
              'bower_components/codemirror/theme/ambiance.css',
              'bower_components/codemirror/lib/codemirror.js',
              'bower_components/codemirror/mode/javascript/javascript.js'
            ]
          }, {
            name: 'ui.codemirror',
            files: ['bower_components/angular-ui-codemirror/ui-codemirror.min.js']
          }]);
        }
      }
    })
    .state('labs.additional-info-mongodb', {
      url: "/additional-info-mongodb",
      templateUrl: "views/labs/additional-info-mongodb/index.html",
      data: {
        pageTitle: 'Additional Information: Using MongoDB'
      },
      resolve: {
        loadPlugin: function($ocLazyLoad) {
          return $ocLazyLoad.load([{
            serie: true,
            files: [
              'bower_components/codemirror/lib/codemirror.css',
              'bower_components/codemirror/theme/ambiance.css',
              'bower_components/codemirror/lib/codemirror.js',
              'bower_components/codemirror/mode/javascript/javascript.js'
            ]
          }, {
            name: 'ui.codemirror',
            files: ['bower_components/angular-ui-codemirror/ui-codemirror.min.js']
          }]);
        }
      }
    })
    .state('labs.additional-info-hdc', {
      url: "/additional-info-hdc",
      templateUrl: "views/labs/additional-info-hdc/index.html",
      data: {
        pageTitle: 'Additional Information: Installing HDC'
      },
      resolve: {
        loadPlugin: function($ocLazyLoad) {
          return $ocLazyLoad.load([{
            serie: true,
            files: [
              'bower_components/codemirror/lib/codemirror.css',
              'bower_components/codemirror/theme/ambiance.css',
              'bower_components/codemirror/lib/codemirror.js',
              'bower_components/codemirror/mode/javascript/javascript.js'
            ]
          }, {
            name: 'ui.codemirror',
            files: ['bower_components/angular-ui-codemirror/ui-codemirror.min.js']
          }]);
        }
      }
    })
    .state('labs.additional-info-xdk', {
      url: "/additional-info-xdk",
      templateUrl: "views/labs/additional-info-xdk/index.html",
      data: {
        pageTitle: 'Additional Information: Debugging Intel XDK'
      },
      resolve: {
        loadPlugin: function($ocLazyLoad) {
          return $ocLazyLoad.load([{
            serie: true,
            files: [
              'bower_components/codemirror/lib/codemirror.css',
              'bower_components/codemirror/theme/ambiance.css',
              'bower_components/codemirror/lib/codemirror.js',
              'bower_components/codemirror/mode/javascript/javascript.js'
            ]
          }, {
            name: 'ui.codemirror',
            files: ['bower_components/angular-ui-codemirror/ui-codemirror.min.js']
          }]);
        }
      }
    })
   .state('index.faq', {
      url: "/faq",
      templateUrl: "views/faq.html",
      data: {
        pageTitle: 'FAQ'
      }
    });
}
angular
  .module('labs')
  .config(config)
  .run(function($rootScope, $state) {
    $rootScope.$state = $state;
  });
