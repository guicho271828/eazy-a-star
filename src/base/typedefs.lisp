(defpackage :eazy-a-star.base
  (:use :cl :trivia)
  (:shadowing-import-from :immutable-struct :defstruct)
  (:nicknames :ea*.b)
  (:export :node :edge
           :priority :id
           ;; 
           :implement-interface
           :define-interface))
(in-package :ea*.b)

(deftype predicate (&optional (arg t)) `(function (,arg) boolean))

(deftype equality (&optional (arg t)) `(function (,arg ,arg) boolean))

(let ((id 0))
  (declare (fixnum id))
  (defstruct id-mixin
    (id (incf id) :type fixnum :reader id)))

(defstruct (node (include :id-mixin))
  (parent nil :type (or null node)))

(defstruct (edge (include :id-mixin))
  (cost 0 :type fixnum)
  (to (error "no edge destination") :type edge))

(deftype priority ()
  `(mod #.array-dimension-limit))
(deftype id () 'fixnum)

;;; interface

(defstruct interface (arguments nil :type list) (ftypes nil :type list))
(lisp-namespace:define-namespace interface interface)

(defmacro define-interface (name args &body ftypes)
  (ematch ftypes
    ((list* (and s (type string)) rest)
     (assert (every #'symbolp rest))
     `(eval-when (:compile-toplevel :load-toplevel :execute)
        (setf (symbol-interface ',name) (interface ',args ',rest))
        (defmacro ,name (,args ,@rest)
          ,(concatenate 'string 
                        s "

The macro is a dummy macro for slime integration.")
          (declare (ignore ,@args ,@rest))
          (error "dummy macro!"))))
    (_
     (assert (every #'symbolp ftypes))
     `(eval-when (:compile-toplevel :load-toplevel :execute)
        (setf (symbol-interface ',name) (interface ',args ',ftypes))
        (defmacro ,name (,args ,@ftypes)
          "This is a dummy macro for slime integration."
          (declare (ignore ,@args ,@ftypes))
          (error "dummy macro!"))))))

(defmacro implement-interface ((name args &body implementations))
  (ematch (symbol-interface name)
    ((interface arguments ftypes)
     (let ((implementations
            (or implementations
                (mapcar (lambda (x) (intern (string x)))
                        ftypes))))

       (assert (= (length ftypes) (length implementations))
               nil
               "mismatch in interface/implementation")
       (assert (= (length arguments) (length args))
               nil
               "mismatch in interface arguments")
       `(declaim ,@(mapcar (lambda (ftype impl)
                             `(cl:ftype (,ftype ,@args) ,impl))
                           ftypes
                           implementations))))))