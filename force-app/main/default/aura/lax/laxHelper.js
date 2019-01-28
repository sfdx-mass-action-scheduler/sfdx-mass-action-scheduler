/*
Version: 1.2.5
GitHub: https://github.com/ruslan-kurchenko/sfdc-lax
 */
/**
 * @license
 * MIT License
 * Copyright (c) 2017 Ruslan Kurchenko
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

/**
 * The controller of Lax Aura Component
 * @namespace LaxHelper
 */

// eslint-disable-next-line no-unused-expressions,strict
(
  {
  /**
   * Initialization function called every time Lax Aura Component instantiated
   * @memberof LaxHelper#
   * @param component {Object} - the lax component object
   */
    init: function init(component) {
      var helper = this,
        contextComponent = component.get('v.context');

      var laxProps = {
        _component: {
          writable: false,
          configurable: false,
          enumerable: false,
          value: contextComponent
        }
      };

      var laxPrototype = this.getLax(function(globalEventListeners) {
        helper.initEventListeners(globalEventListeners, contextComponent, 'onLaxPrototypeInit');
      });

      var localEventListeners = {};
      helper.initEventListeners(localEventListeners, contextComponent, 'onLaxInit');

      // Create an object that is inherit all the functionality from
      // the Lax object due to prototype inheritance
      var lax = Object.create(laxPrototype, laxProps);

      lax.getEventListeners = function () {
        return localEventListeners;
      };

      // Create property on the context component object that is refer on
      // newly created Lax object
      var contextComponentAttribute = component.get('v.attributeName');
      var componentProps = {
        writable: false,
        configurable: false,
        enumerable: false,
        value: lax
      };
      Object.defineProperty(contextComponent, contextComponentAttribute, componentProps);
    },

    /**
   * The function creates the Lax object and save it on the helper.
   * Helpers of Aura components are static, it allows to share prototype
   * Lax object on a helper instance.
   * @memberOf LaxHelper#
   * @returns {Lax}
   */
    getLax: function getLax(onInit) {
      if (!this._lax) {
        this._lax = this.createLax(onInit);
      }

      return this._lax;
    },

    /**
   * Creates a prototype Lax object.
   * The function calls when the first Lax component in the app instantiates.
   * @memberOf LaxHelper#
   * @returns {Lax}
   */
    createLax: function createLax(onInit) {
      var helper = this;

      var errors = helper.defineErrors();
      var eventListeners = {};

      /**
     * Creates a unified function to be assign as a callback on the aura action.
     * @param resolve {Function} the function called if the action is success
     * @param reject {Function} the function called if the action is failed
     * @returns {Function}
     */
      function actionRouter(resolve, reject, finallyCallback) {
        var lax = this;

        return function (response) {
          var state = response.getState(),
            listOfListeners = [
              laxPrototype.getEventListeners(), lax.getEventListeners()
            ];

          if (state === 'SUCCESS') {
            var resultValue = util
              .getEventListenersByName(listOfListeners, 'apexAction.onSuccess')
              .reduce(function (val, listener) {
                return listener(val);
              }, response.getReturnValue());

            resolve(resultValue);
          } else {
            var message = 'Unknown error';

            var responseErrors = response.getError();
            if (responseErrors && Array.isArray(responseErrors) && responseErrors.length > 0) {
              message = responseErrors[0].message;
            }

            var errorConstructor = state === 'INCOMPLETE' ? errors.IncompleteActionError : errors.ApexActionError;

            var err = util
              .getEventListenersByName(listOfListeners, 'apexAction.onError')
              .reduce(function (err, listener) {
                return listener(err);
              }, new errorConstructor(message, responseErrors, response));

            reject(err);
          }

          if (finallyCallback) {
            finallyCallback();
          }
        };
      }

      /**
     * Creates a unified function to be assign as a callback on the component creation action.
     * @param resolve {Function} the function called if the component creation successfully
     * @param reject {Function} the function called if the component failed to create
     * @returns {Function}
     */
      function createComponentActionRouter(resolve, reject) {
        var lax = this;

        return function (component, status, message) {
          var result = { status: status },
            isMultiple = $A.util.isArray(message),
            listOfListeners = [
              laxPrototype.getEventListeners(), lax.getEventListeners()
            ];

          if (isMultiple) {
            result.components = component;
            result.statusMessages = message;
          } else {
            result.component = component;
            result.message = message;
          }

          if (status === 'SUCCESS') {
            var resultComponent = util
              .getEventListenersByName(listOfListeners, 'createComponentAction.onSuccess')
              .reduce(function (cmp, listener) {
                return listener(cmp)
              }, component);

            resolve(resultComponent);
          } else {
            var errorConstructor = status === 'INCOMPLETE' ? errors.IncompleteActionError : errors.CreateComponentError,
              error = null;

            if (isMultiple) {
              var msg = 'An error occurred while a component creation process.';
              error = new errorConstructor(msg, result.statusMessages, result);
            } else {
              error = new errorConstructor(message, null, result);
            }

            var resultError = util
              .getEventListenersByName(listOfListeners, 'createComponentAction.onError')
              .reduce(function (e, listener) {
                return listener(e);
              }, error);

            reject(resultError);
          }
        };
      }


      /**
       * Creates a unified function to assign it as a callback on the LDS action.
       * The returned function is a router for the result of the action.
       * @param resolve {Function} the function called if the action is success
       * @param reject {Function} the function called if the action is failed
       * @returns {Function}
       */
      function ldsActionRouter(resolve, reject) {
        var lax = this;

        return function(result) {
          var listOfListeners = [
              laxPrototype.getEventListeners(), lax.getEventListeners()
            ];

          if (result.state === 'SUCCESS' || result.state === 'DRAFT') {
            var resultValue = util
              .getEventListenersByName(listOfListeners, 'ldsAction.onSuccess')
              .reduce(function (val, listener) {
                return listener(val);
              }, result);

            resolve(resultValue);
          } else {
            var error = null;
            if (result.state === 'ERROR') {
              var message = 'Unknown error';

              if (result.error && Array.isArray(result.error) && result.error.length > 0) {
                message = result.error[0].message;
              }

              error = new errors.LdsActionError(message, result.error, result);
            } else if (result.state === 'INCOMPLETE') {
              error = new errors.IncompleteActionError('You are currently offline.', result.error, result);
            } else {
              error = new Error('Unknown action state');
            }

            var resultError = util
              .getEventListenersByName(listOfListeners, 'ldsAction.onError')
              .reduce(function (e, listener) {
                return listener(e);
              }, error);

            reject(resultError);
          }
        };
      }

      var util = {
      /**
       * Create an object and bind it with passed in Promise prototype.
       * It has own chaining functions (<code>then</code>, <code>catch</code>),
       * with Aura context functionality. It allows to avoid of <code>$A.getCallback</code>
       * on callback functions.
       * @param promise {Promise}
       * @returns {LaxPromise}
       */
        createAuraContextPromise: function (promise) {
          var lp = Object.create(promise);
          Object.defineProperty(lp, '_contextPromise', {
            writable: false,
            configurable: false,
            enumerable: true,
            value: promise
          });
          // eslint-disable-next-line no-use-before-define
          return Object.assign(lp, laxPromise);
        },

        removeAuraErrorMessagePrefix: function (message) {
          var result = message;
          var prefix = 'Error in $A.getCallback() [';

          if (message && message.indexOf(prefix) > -1) {
              result = message.replace(prefix, '').slice(0, -1)
          }

          return result;
        },

        assignCatchFilters: function (handleErrors, callback, promise) {
          return function routeError(error) {
            for (var i = 0; i < handleErrors.length; i = i + 1) {
              var errorType = handleErrors[i];
              if (errorType === Error ||
              (errorType !== null && errorType.prototype instanceof Error)) {

                if (error instanceof errorType || error.name === errorType.name) {
                  return util.tryCatch(callback).call(promise, error);
                }
              }
            }

            return Promise.reject(error);
          };
        },

        tryCatch: function (callback) {
          return function tryCallback() {
            try {
              return callback.apply(this, arguments);
            } catch (e) {
              return Promise.reject(e);
            }
          };
        },

        registerError: function (error) {
          errors[error.name] = error;
        },

        isApplicationEvent: function (eventName) {
          return eventName.indexOf('e.') === 0 && eventName.indexOf(':') > 0;
        },

        getEventListenersByName: function (listOfListeners, eventHandlerName) {
          var handlers = [];

          listOfListeners.forEach(function (listeners) {
            util.pushIfValueExist(
              handlers,
              util.delve(listeners, eventHandlerName)
            );
          });

          return handlers;
        },

        /**
         * {@link https://github.com/developit/dlv}
         */
        delve: function (obj, key, def, p) {
          p = 0;
          key = key.split ? key.split('.') : key;
          while (obj && p < key.length) obj = obj[key[p++]];
          return (obj === undefined || p < key.length) ? def : obj;
        },

        pushIfValueExist: function (arr, value) {
          if (!$A.util.isUndefinedOrNull(value)) arr.push(value);
        }
      };

      /**
     * The container of the actual context promise.
     * It helps to call chain function (<code>then</code>, <code>catch</code>)
     * in the Aura context. The client can avoid of <code>$A.getCallback</code> calls.
     * @class LaxPromise
     */
      var laxPromise =
    /**
     * @lends LaxPromise#
     */
    {
      /**
       * Attaches callbacks for the resolution and/or rejection of the Promise.
       * @param onSuccess {Function|undefined} The callback to execute when the Promise is resolved.
       * @param onError {Function=} The callback to execute when the Promise is rejected.
       * @returns {LaxPromise} A {@link LaxPromise} for the completion of which ever callback is executed.
       */
      then: function (onSuccess, onError) {
        var promise = this._contextPromise.then(
          (onSuccess ?  $A.getCallback(onSuccess) : undefined),
          (onError ?  $A.getCallback(onError) : undefined)
        );

        return util.createAuraContextPromise(promise);
      },

      /**
       * Attaches a callback for only the rejection of the Promise.
       * @param onError {Function} The callback to execute when the Promise is rejected.
       * @returns {LaxPromise} A {@link LaxPromise} for the completion of the callback.
       * @example
       * component.lax.enqueue('c.save', { record: record })
       *  .then(id => {
       *    component.set('v.record.id', id);
       *  })
       *  .catch(errors => {
       *    console.error(errors);
       *  });
       */
      catch: function (onError) {
        var promise;
        var callback = onError;
        var len = arguments.length;
        if (len > 1) {
          var errorTypes = new Array(len - 1);
          for (var i = 0; i < len - 1; i = i + 1) {
            errorTypes[i] = arguments[i];
          }
          var onErrorCallback = arguments[len - 1];

          callback = util.assignCatchFilters(errorTypes, onErrorCallback, this);
        }

        promise = this.then(undefined, function(e) {
          e.message = util.removeAuraErrorMessagePrefix(e.message);
          return callback(e);
        });

        return util.createAuraContextPromise(promise);
      },

      /**
       * The method returns a {@link LaxPromise}.
       * When the Promise is settled, whether fulfilled or rejected, the specified callback function is executed.
       * This provides a way for code that must be executed once the Promise has been dealt with to be run
       * whether the promise was fulfilled successfully or rejected.
       *
       * This lets you avoid duplicating code in both the promise's then() and catch() handlers.
       * @param callback {Function} The function to run whe the Promise is settled
       * @returns {LaxPromise}
       */
      finally: function (callback) {
        var self = this,
          promise;

        if (typeof Promise.prototype.finally === 'function') {
          promise = self._contextPromise.finally($A.getCallback(callback));
        } else {
          promise = this
            .then(function(value) {
              return self._contextPromise.constructor.resolve($A.getCallback(callback)()).then(function() { return value; });
            })
            .catch(function(reason) {
              return self._contextPromise.constructor.resolve($A.getCallback(callback)()).then(function() { throw reason; });
            });
        }

        return util.createAuraContextPromise(promise);
      },

      /**
       * Attaches a callback for only the rejection of the Promise
       * and for only actions that returns "ERROR" state
       * @param onError {Function} The callback to execute when the Promise is rejected.
       * @returns {LaxPromise} A {@link LaxPromise} for the completion of the callback.
       */
      error: function (onError) {
        var fn = util.assignCatchFilters([errors.ApexActionError, errors.CreateComponentError], onError, this);
        return this.then(undefined, fn);
      },

      /**
       * Attaches a callback for only the rejection of the Promise
       * and for only actions that returns "INCOMPLETE" state
       * @param onIncomplete {Function} The callback to execute when the Promise is rejected.
       * @returns {LaxPromise} A {@link LaxPromise} for the completion of the callback.
       */
      incomplete: function (onIncomplete) {
        var fn = util.assignCatchFilters([errors.IncompleteActionError], onIncomplete, this);
        return this.then(undefined, fn);
      }
    };

      /**
     * The container of the actual Lightning Data Service (LDS). It delegates
     * actions to LDS and provide and API to chain them. Actions callback functions don't
     * require <code>$A.getCallback()</code> wrapper.
     * @class LaxDataService
     */
      var laxDataService =
    /**
     * @lends LaxDataService#
     */
    {

      /**
       * The function to save the record that loaded to LDS edit <code>EDIT</code> mode.
       * It used to create a record and save it or to save the changes to an existing one.
       * @see https://developer.salesforce.com/docs/atlas.en-us.lightning.meta/lightning/data_service_save_record.htm
       * @returns {LaxPromise}
       */
      saveRecord: function () {
        var self = this;
        var promise = new Promise(function (resolve, reject) {
          self._service.saveRecord(ldsActionRouter.call(self, resolve, reject));
        });

        return util.createAuraContextPromise(promise);
      },

      /**
       * The function to load a record template to the LDS <code>targetRecord</code> attribute.
       * It doesn't return a result to callback function.
       * It simply prepares an empty record and assigns it to the <code>targetRecord</code> attribute.
       * @param sobjectType {String=} the object API name for the new record.
       * @param recordTypeId {String=} the 18 character ID of the record type for the new record.
       * If not specified, the default record type for the object is used, as defined in the user’s profile.
       * @param skipCache {Boolean=} whether to load the record template from the server instead of the
       * client-side Lightning Data Service cache. Defaults to false.
       * @returns {LaxPromise}
       */
      getNewRecord: function (sobjectType, recordTypeId, skipCache) {
        var self = this;
        var promise = new Promise(function (resolve) {
          function getNewRecordCallback () {
            resolve();
          }

          self._service.getNewRecord(sobjectType, recordTypeId, skipCache, getNewRecordCallback);
        });

        return util.createAuraContextPromise(promise);
      },

      /**
       * The function to delete a record using LDS.
       * @returns {LaxPromise}
       */
      deleteRecord: function () {
        var self = this;
        var promise = new Promise(function (resolve, reject) {
          self._service.deleteRecord(ldsActionRouter.call(self, resolve, reject));
        });

        return util.createAuraContextPromise(promise);
      }
    };

      /**
     * The object based on builder pattern to call Aura action.
     * It is instantiated to be used by {@link Lax} as a prototype of actual actions.
     * This type of action does not use Promise approach and subsequently can be called as storable.
     * @class LaxActionBuilder
     */
      var laxActionBuilder =
    /**
     * @lends LaxActionBuilder#
     */
    {

      /**
       * Assign the success callback on Aura action
       * @param callback {Function}
       * @returns {LaxActionBuilder}
       */
      setThen: function setThen(callback) {
        this._resolveCallback = callback;
        return this;
      },

      /**
       * Assigns the failure callback on Aura action. This function called when the error occurs.
       * @param callback {Function}
       * @returns {LaxActionBuilder}
       */
      setCatch: function setCatch(callback) {
        this._rejectCallback = callback;
        return this;
      },

      /**
       * Assigns the finally callback on Aura action. This function called after success or failure callback. It doesn't
       * depend on the result of an action.
       * @param callback {Function}
       * @returns {LaxActionBuilder}
       */
      setFinally: function setFinally(callback) {
        this._finallyCallback = callback;
        return this;
      },

      /**
       * Sets parameters for the action.
       * @param params {Object}
       * @returns {LaxActionBuilder}
       */
      setParams: function setParams(params) {
        this._action.setParams(params);
        return this;
      },

      /**
       * Marks the action as a {@link https://developer.salesforce.com/docs/atlas.en-us.lightning.meta/lightning/controllers_server_storable_actions.htm|Storable}
       * @returns {LaxActionBuilder}
       */
      setStorable: function setStorable() {
        this._action.setStorable();
        return this;
      },

      /**
       * Marks the action as a {@link https://developer.salesforce.com/docs/atlas.en-us.lightning.meta/lightning/controllers_server_background_actions.htm|Background}
       * @returns {LaxActionBuilder}
       */
      setBackground: function setBackground() {
        this._action.setBackground();
        return this;
      },

      /**
       * Enqueues the action. The function do not return the object itself and should be
       * called at the end of the builder chain.
       * @returns {void}
       */
      enqueue: function enqueue() {
        this._action.setCallback(this._component,
          actionRouter.call(this._lax, this._resolveCallback, this._rejectCallback, this._finallyCallback));
        $A.enqueueAction(this._action);
      }

    };

      /**
     * The object based on builder pattern to fire Lightning Application or Component events.
     * @class LaxEventBuilder
     */
      var laxEventBuilder =
      /**
       * @lends LaxEventBuilder#
       */
      {
      /**
       * Sets data for the event attributes. A parameter’s name must match the name attribute
       * of one of the event’s <code>aura:attribute</code> tags.
       * @param params {Object} the data of event attributes
       * @returns {LaxEventBuilder}
       */
        setParams: function setParams(params) {
          this._event.setParams(params);
          return this;
        },

        /**
       * Fires the event.
       * @returns {void}
       */
        fire: function fire() {
          this._event.fire();
        }

      };

      /**
     * The object with list of Aura Server-Side action options
     * @typedef {Object} ActionOptions
     * @property storable {Boolean} Marks action as a <a href="https://developer.salesforce.com/docs/atlas.en-us.lightning.meta/lightning/controllers_server_storable_actions.htm">Storable</a>
     * @property background {Boolean} Marks action as a <a href="https://developer.salesforce.com/docs/atlas.en-us.lightning.meta/lightning/controllers_server_background_actions.htm">Background</a>
     * @property abortable {Boolean} Marks action as a <a href="https://developer.salesforce.com/docs/atlas.en-us.lightning.meta/lightning/controllers_server_abortable_actions.htm">Abortable</a>
     */

      /**
     * The object that contains a properties for Aura Server-Side Action
     * @typedef {Object} ActionProperties
     * @property name {String} The name of the action. It must be the same as Apex @AuraEnabled method
     * @property params {Object} The object with parameters values for the action. It is based on Apex @AuraEnabled method
     * @property options {Object} The object with list of options that can be applied to the action
     */

      /**
     * The action main object of the component that is used as a shared prototype across all lax components
     * created in the application. See <code>init</code> function of the laxHelper.js where the lax assigned as prototype.
     * @class Lax
     */
      var laxPrototype =
      /**
       * @lends Lax#
       */
      {
      /**
       * Enqueues the action by the name and with passed in params and options.
       * The function returns Promise, subsequently client can chain the actions
       * by assigning <code>then</code> callbacks or handle the error by <code>catch</code> callback.
       * @param actionName {String} the name of the action (Apex controller method name)
       * @param params [Object] the object that contains parameters for the action
       * @param options [ActionOptions] the object with list of options for the action
       * @returns {LaxPromise}
       * @example
       * component.lax.enqueue('c.getContact', { id: recordId }, { background: true })
       *   .then(contact => {
       *     component.set('v.record', contact);
       *   });
       */
        enqueue: function enqueue(actionName, params, options) {
          var self = this;
          var promise = new Promise(function (resolve, reject) {
            var action = self._component.get(actionName);

            if (params) {
              action.setParams(params);
            }

            if (options) {
              if (options.background) {
                action.setBackground();
              }
              if (options.storable) {
                action.setStorable();
              }
            }

            action.setCallback(self._component, actionRouter.call(self, resolve, reject));
            $A.enqueueAction(action);
          });

          return util.createAuraContextPromise(promise);
        },

        /**
       * Enqueues the list of actions parallel.
       * The function return {@link Promise} that subsequently can be used to chain callback.
       * The success callback assigned on the {@link Promise} called after all actions ready and an error have not thrown.
       * @param actions {ActionProperties[]}
       * @returns {LaxPromise}
       * @example
       * component.lax.enqueueAll([
       *   // { name : '...', params: {...}, options: {...} }
       *   { name: 'c.getContacts' },
       *   { name: 'c.getAccounts' },
       *   { name: 'c.getOpportunities' }
       * ])
       * .then(results => {
       *   // results: [ [contacts], [accounts], [opportunities] ]
       *   var contacts = results[0];
       *   var accounts = results[1];
       *   var opportunities = results[2];
       * });
       */
        enqueueAll: function enqueueAll(actions) {
          var self = this;
          var promises = actions.map(function (a) {
            return self.enqueue.call(self, a.name, a.params, a.options);
          });

          return util.createAuraContextPromise(Promise.all(promises));
        },

        /**
       * Creates the action linked to {@link LaxActionBuilder} by the provided name.
       * @param actionName {String} the name of the action (Apex controller method)
       * @returns {LaxActionBuilder}
       * @example
       * component.lax
       *  .action('c.getContact')
       *  .setStorable()
       *  .setParams({ id: recordId })
       *  .setThen(contact => {
       *    component.set('v.record', contact)
       *  })
       *  .setCatch(error => {
       *    console.error(error);
       *  })
       *  .enqueue();
       */
        action: function action(actionName) {
          var c = this._component;
          var props = {
            _component: {
              writable: false,
              configurable: false,
              enumerable: false,
              value: c
            },
            _action: {
              writable: false,
              configurable: false,
              enumerable: false,
              value: c.get(actionName)
            },
            _lax: {
              writable: false,
              configurable: false,
              enumerable: false,
              value: this
            }
          };
          return Object.create(laxActionBuilder, props);
        },

        /**
       * Creates an object with {LaxEventBuilder} prototype with the context
       * event by provided name. The function apply Application and Component event name.
       * @param eventName {String} the name of the event
       * @returns {LaxEventBuilder}
       */
        event: function event(eventName) {
          var props = {
            _event: {
              writable: false,
              configurable: false,
              enumerable: false,
              value: util.isApplicationEvent(eventName) ? $A.get(eventName) : this._component.getEvent(eventName)
            }
          };
          return Object.create(laxEventBuilder, props);
        },

        /**
       * Creates a container of actual Lightning Data Service object.
       * @param id {String} the aura:id of the <code>force:record</code> (Lightning Data Service) tag
       * @returns {LaxDataService}
       */
        lds: function lds(id) {
          var service = this._component.find(id);
          var serviceProp = {
            _service: {
              writable: false,
              configurable: false,
              enumerable: false,
              value: service
            }
          };

          return Object.create(laxDataService, serviceProp);
        },

        /**
       * Create a component from a type and a set of attributes.
       * It accepts the name of a type of component, a map of attributes,
       * and returns {LaxPromise} to assign a callback function to notify caller.
       * @param {String} type The type of component to create, e.g. "ui:button".
       * @param {Object} attributes A map of attributes to send to the component. These take the same form as on the markup,
       * including events <code>{"press":component.getReference("c.handlePress")}</code>, and id <code>{"aura:id":"myComponentId"}</code>.
       * @example
       * lax.createComponent("aura:text",{value:'Hello World'})
       *   .then(function(auraTextComponent){
       *        // auraTextComponent - is an instance of aura:text containing the value Hello World
       *   });
       * @returns {LaxPromise}
       */
        createComponent: function createComponent(type, attributes) {
          var self = this;
          var promise = new Promise(function (resolve, reject) {
            $A.createComponent(type, attributes, createComponentActionRouter.call(self, resolve, reject));
          });

          return util.createAuraContextPromise(promise);
        },

        /**
       * Create an array of components from a list of types and attributes.
       * It accepts a list of component names and attribute maps, and returns
       * {LaxPromise} to assign a callback function to notify caller.
       * @param {Array} components The list of components to create, e.g. <code>["ui:button",{"press":component.getReference("c.handlePress")}]</code>
       * @example
       * lax.createComponents([
       *      ["aura:text",{value:'Hello'}],
       *      ["ui:button",{label:'Button'}],
       *      ["aura:text",{value:'World'}]
       *  ])
       *  .then(function(components) {
       *      // components - is an array of 3 components
       *      // 0 - Text Component containing Hello
       *      // 1 - Button Component with label Button
       *      // 2 - Text component containing World
       *  });
       *  @return {LaxPromise}
       */
        createComponents: function createComponents(components) {
          var self = this;
          var promise = new Promise(function (resolve, reject) {
            $A.createComponents(components, createComponentActionRouter.call(self, resolve, reject));
          });

          return util.createAuraContextPromise(promise);
        },

        getEventListeners: function () {
          return eventListeners;
        },

        util: {
          registerError: util.registerError
        },

        errors: errors
      };

      if (onInit) {
        // callback to decorate events workflow (ApexAction)
        onInit(eventListeners);
      }

      return laxPrototype;
    },

    initEventListeners: function (listenersContainer, component, auraMethodName) {
      var method = component[auraMethodName];
      if (method) {
        Object.assign(listenersContainer, method.call(component));
      }
    },

    defineErrors: function () {
      function ApexActionError(message, entries, action) {
        this.name = 'ApexActionError';
        this.message = message;
        this.entries = entries;
        this.action = action;
        this.stack = (new Error()).stack;
      }
      ApexActionError.prototype = Object.create(Error.prototype);


      function IncompleteActionError(message, entries, action) {
        this.name = 'IncompleteActionError';
        this.message = message;
        this.entries = entries;
        this.action = action;
        this.stack = (new Error()).stack;
      }
      IncompleteActionError.prototype = Object.create(Error.prototype);

      function LdsActionError(message, entries, action) {
        this.name = 'LdsActionError';
        this.message = message;
        this.entries = entries;
        this.action = action;
        this.stack = (new Error()).stack;
      }
      LdsActionError.prototype = Object.create(Error.prototype);

      function CreateComponentError(message, entries, action) {
        this.name = 'CreateComponentError';
        this.message = message;
        this.entries = entries;
        this.action = action;
        this.stack = (new Error()).stack;
      }
      CreateComponentError.prototype = Object.create(Error.prototype);

      return {
        ApexActionError: ApexActionError,
        IncompleteActionError: IncompleteActionError,
        LdsActionError: LdsActionError,
        CreateComponentError: CreateComponentError
      };
    }
  });