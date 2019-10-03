(define (spreadsheet)
  (init-array)
  (set-selection-cell-id! (make-id 1 1))
  (set-screen-corner-cell-id! (make-id 1 1))
  (command-loop))

(define (command-loop)
  (print-screen)
  (let ((command-or-formula (read)))
    (if (equal? command-or-formula 'exit)
        "Bye!"
        (begin (process-command command-or-formula)
               (command-loop)))))

(define (process-command command-or-formula)
  (cond ((and (list? command-or-formula)
              (command? (car command-or-formula)))
         (execute-command command-or-formula))
        ((command? command-or-formula)
         (execute-command (list command-or-formula 1)))
        (else (exhibit (ss-eval (pin-down command-or-formula
                                          (selection-cell-id)))))))

(define (execute-command command)
  (apply (get-command (car command))
         (cdr command)))

(define (exhibit val)
  (show val)
  (show "Type RETURN to redraw screen")
  (read-line)
  (read-line))

;;; Spreadsheet size

(define *total-cols* 26)

(define *total-rows* 30)

;;; Commands

;; Cell selection commands: F, B, N, P, and SELECT

(define (prev-row delta)
  (let ((row (id-row (selection-cell-id))))
    (if (< (- row delta) 1)
        (error "Already at top.")
        (begin (log-undo-cmd next-row (list delta))  ; exercise-25.10
               (set-selected-row! (- row delta))))))

(define (next-row delta)
  (let ((row (id-row (selection-cell-id))))
    (if (> (+ row delta) *total-rows*)
        (error "Already at bottom.")
        (begin (log-undo-cmd prev-row (list delta))  ; exercise-25.10
               (set-selected-row! (+ row delta))))))

(define (prev-col delta)
  (let ((col (id-column (selection-cell-id))))
    (if (< (- col delta) 1)
        (error "Already at left.")
        (begin (log-undo-cmd next-col (list delta))  ; exercise-25.10
               (set-selected-column! (- col delta))))))

(define (next-col delta)
  (let ((col (id-column (selection-cell-id))))
    (if (> (+ col delta) *total-cols*)
        (error "Already at right.")
        (begin (log-undo-cmd prev-col (list delta))  ; exercise-25.10
               (set-selected-column! (+ col delta))))))

(define (set-selected-row! new-row)
  (select-id! (make-id (id-column (selection-cell-id)) new-row)))

(define (set-selected-column! new-column)
  (select-id! (make-id new-column (id-row (selection-cell-id)))))

(define (select-id! id)
  (set-selection-cell-id! id)
  (adjust-screen-boundaries))

(define (select cell-name)
  (log-undo-cmd select-id! (list (selection-cell-id)))
  (select-id! (cell-name->id cell-name)))

(define (adjust-screen-boundaries)
  (let ((row (id-row (selection-cell-id)))
        (col (id-column (selection-cell-id))))
    (if (< row (id-row (screen-corner-cell-id)))
        (set-corner-row! row)
        'do-nothing)
    (if (>= row (+ (id-row (screen-corner-cell-id)) 20))
        (set-corner-row! (- row 19))
        'do-nothing)
    (if (< col (id-column (screen-corner-cell-id)))
        (set-corner-column! col)
        'do-nothing)
    (if (>= col (+ (id-column (screen-corner-cell-id)) 6))
        (set-corner-column! (- col 5))
        'do-nothing)))

(define (set-corner-row! new-row)
  (set-screen-corner-cell-id!
    (make-id (id-column (screen-corner-cell-id)) new-row)))

(define (set-corner-column! new-column)
  (set-screen-corner-cell-id!
    (make-id new-column (id-row (screen-corner-cell-id)))))

;; Window selection commands: window-f, window-b, window-n, window-p

(define (win-p delta)
  (let ((row (id-row (screen-corner-cell-id))))
    (if (< (- row delta) 1)
        (error "Already shown the top row")
        (begin (log-undo-cmd win-n (list delta))  ; exercise-25.10
               (set-corner-row! (- row delta))))))

(define (win-n delta)
  (let ((row (id-row (screen-corner-cell-id))))
    (if (> (+ row delta 19) *total-rows*)
        (error "Already shown the bottom row")
        (begin (log-undo-cmd win-p (list delta))  ; exercise-25.10
               (set-corner-row! (+ row delta))))))

(define (win-b delta)
  (let ((col (id-column (screen-corner-cell-id))))
    (if (< (- col delta) 1)
        (error "Already shown the left-most column")
        (begin (log-undo-cmd win-f (list delta)) ; exercise-25.10
               (set-corner-column! (- col delta))))))

(define (win-f delta)
  (let ((col (id-column (screen-corner-cell-id))))
    (if (> (+ col delta 5) *total-cols*)
        (error "Already shown the right-most column")
        (begin (log-undo-cmd win-b (list delta)) ; exercise-25.10
               (set-corner-column! (+ col delta))))))

;; column decimal digit command

(define (col-decimal num . where)
  (let ((col (if (null? where)
                 (id-column (selection-cell-id))
                 (letter->number (car where)))))
    (if (and (> col 0) (< col *total-cols*))
        (begin (log-undo-cmd set-col-decimal-digit! ; exercise-25.10
                             (list col (col-decimal-digit col)))
               (set-col-decimal-digit! col num))
        #f)))

;; undo command exercise-25.10

(define (undo anything)  ; the argument allows users use undo instead of (undo)
  (if (null? (vector-ref *undo-cmd-data* 0))
      (if (null-data? *undo-put-data* (- (vector-length *undo-put-data*) 1))
          (begin (newline)
                 (display "already the oldest command"))
          (undo-put))
      (apply (vector-ref *undo-cmd-data* 0)
             (vector-ref *undo-cmd-data* 1))))

(define (null-data? data index)
  (cond ((< index 0) #t)
        ((null? (vector-ref data index))
         (null-data? data (- index 1)))
        (else #f)))

(define (undo-put)
 (undo-put-helper *undo-put-data*
                  (- (vector-length *undo-put-data*) 1)))

(define (undo-put-helper data index)
  (cond ((< index 0) 'done)
        ((null? (vector-ref data index))
         (undo-put-helper data (- index 1)))
        (else (begin (apply put-formula-in-cell (vector-ref *undo-put-data* index))
               (undo-put-helper data (- index 1))))))

;; LOAD

(define (spreadsheet-load filename)
  (let ((port (open-input-file filename)))
    (sl-helper port)
    (close-input-port port)))

(define (sl-helper port)
  (let ((command (read port)))
    (if (eof-object? command)
        'done
        (begin (show command)
               (process-command command)
               (sl-helper port)))))


;; PUT

; (define (put formula . where)
;   (cond ((null? where)
;          (put-formula-in-cell formula (selection-cell-id)))
;         ((cell-name? (car where))
;          (put-formula-in-cell formula (cell-name->id (car where))))
;         ((number? (car where))
;          (put-all-cells-in-row formula (car where)))
;         ((letter? (car where))
;          (put-all-cells-in-col formula (letter->number (car where))))
;         (else (error "Put it where?"))))

(define (put formula . where)
  (init-undo-data *undo-cmd-data*)
  (init-undo-data *undo-put-data*)
  (put-helper formula where 0))

(define (put-helper formula where modified-num)
  (cond ((null? where)
         (begin (display-status (+ 1 modified-num))
                (put-formula-in-cell formula (selection-cell-id))))
        ((cell-name? (car where))
         (begin (display-status (+ 1 modified-num))
                (put-formula-in-cell formula (cell-name->id (car where)))))
        ((number? (car where))
         (begin (display-status (if (null? formula)
                                    *total-cols*
                                    (noval-cells (car where))))
                (put-all-cells-in-row formula (car where))))
        ((letter? (car where))
         (begin (display-status (if (null? formula)
                                    *total-rows*
                                    (noval-cells (car where))))
                (put-all-cells-in-col formula (letter->number (car where)))))
        (else (error "Put it where?")))
  )

(define (display-status num)
  (newline)
  (display "status: ")
  (display num)
  (if (> num 1)
      (display " cells modified")
      (display " cell modified")))

(define (noval-cells row-or-col)   ; return the number of the cells which has no values
  (if (number? row-or-col)
      (noval-row-cells row-or-col *total-cols* 0)
      (noval-col-cells row-or-col *total-rows* 0)))

(define (noval-row-cells row total-cells noval-cell-num)
  (cond ((= total-cells 0) noval-cell-num)
        ((null? (cell-value (make-id total-cells row)))
         (noval-row-cells row (- total-cells 1) (+ noval-cell-num 1)))
        (else (noval-row-cells row (- total-cells 1) noval-cell-num))))

(define (noval-col-cells col total-cells noval-cell-num)
  (cond ((= total-cells 0) noval-cell-num)
        ((null? (cell-value (make-id (letter->number col) total-cells)))
         (noval-col-cells col (- total-cells 1) (+ noval-cell-num 1)))
        (else (noval-col-cells col (- total-cells 1) noval-cell-num))))

(define (put-all-cells-in-row formula row)
  (put-all-helper formula (lambda (col) (make-id col row)) 1 *total-cols*))

(define (put-all-cells-in-col formula col)
  (put-all-helper formula (lambda (row) (make-id col row)) 1 *total-rows*))

(define (put-all-helper formula id-maker this max)
  (if (> this max)
      'done
      (begin (try-putting formula (id-maker this))
             (put-all-helper formula id-maker (+ 1 this) max))))

(define (try-putting formula id)
  (if (or (null? (cell-value id)) (null? formula))
      (put-formula-in-cell formula id)
      'do-nothing))

(define (put-formula-in-cell formula id)
  (log-undo-put (cell-expr id) id) ; exercise-25.10
  (put-expr (pin-down formula id) id))


;;; The Association List of Commands

(define (command? name)
  (assoc name *the-commands*))

(define (get-command name)
  (let ((result (assoc name *the-commands*)))
    (if (not result)
        #f
        (cadr result))))

;(define *the-commands*
;  (list (list 'p prev-row)
;        (list 'n next-row)
;        (list 'b prev-col)
;        (list 'f next-col)
;        (list 'select select)
;        (list 'put put)
;        (list 'load spreadsheet-load)))

(define *the-commands*
  (list (list 'p prev-row)
        (list 'n next-row)
        (list 'b prev-col)
        (list 'f next-col)
        (list 'select select)
        (list 'window-p win-p)
        (list 'window-n win-n)
        (list 'window-b win-b)
        (list 'window-f win-f)
        (list 'put put)
        (list 'load spreadsheet-load)
        (list 'col-decimal col-decimal)
        (list 'undo undo)))  ; exercise-25.10


;;; Pinning Down Formulas Into Expressions

(define (pin-down formula id)
  (cond ((cell-name? formula) (cell-name->id formula))
        ((word? formula) formula)
        ((null? formula) '())
        ((equal? (car formula) 'cell)
         (pin-down-cell (cdr formula) id))
        (else (bound-check
                (map (lambda (subformula) (pin-down subformula id))
                     formula)))))

(define (bound-check form)
  (if (member 'out-of-bounds form)
      'out-of-bounds
      form))

(define (pin-down-cell args reference-id)
  (cond ((null? args)
         (error "Bad cell specification: (cell)"))
        ((null? (cdr args))
         (cond ((number? (car args))         ; they chose a row
                (make-id (id-column reference-id) (car args)))
               ((letter? (car args))         ; they chose a column
                (make-id (letter->number (car args))
                         (id-row reference-id)))
               (else (error "Bad cell specification:"
                            (cons 'cell args)))))
        (else
          (let ((col (pin-down-col (car args) (id-column reference-id)))
                (row (pin-down-row (cadr args) (id-row reference-id))))
            (if (and (>= col 1) (<= col *total-cols*) (>= row 1) (<= row *total-rows*))
                (make-id col row)
                'out-of-bounds)))))

(define (pin-down-col new old)
  (cond ((equal? new '*) old)
        ((equal? (first new) '>) (+ old (bf new)))
        ((equal? (first new) '<) (- old (bf new)))
        ((letter? new) (letter->number new))
        (else (error "What column?"))))

(define (pin-down-row new old)
  (cond ((number? new) new)
        ((equal? new '*) old)
        ((equal? (first new) '>) (+ old (bf new)))
        ((equal? (first new) '<) (- old (bf new)))
        (else (error "What row?"))))


;;; Dependency Management

(define (put-expr expr-or-out-of-bounds id)
  (let ((expr (if (equal? expr-or-out-of-bounds 'out-of-bounds)
                  '()
                  expr-or-out-of-bounds)))
    (for-each (lambda (old-parent)
                (set-cell-children!
                  old-parent
                  (remove id (cell-children old-parent))))
              (cell-parents id))
    (set-cell-expr! id expr)
    (set-cell-parents! id (remdup (extract-ids expr)))
    (for-each (lambda (new-parent)
                (set-cell-children!
                  new-parent
                  (cons id (cell-children new-parent))))
              (cell-parents id))
    (figure id)))

(define (extract-ids expr)
  (cond ((id? expr) (list expr))
        ((word? expr) '())
        ((null? expr) '())
        (else (append (extract-ids (car expr))
                      (extract-ids (cdr expr))))))

(define (figure id)
  (cond ((null? (cell-expr id)) (setvalue id '()))
        ((all-evaluated? (cell-parents id))
         (setvalue id (ss-eval (cell-expr id))))
        (else (setvalue id '()))))

(define (all-evaluated? ids)
  (cond ((null? ids) #t)
        ((not (number? (cell-value (car ids)))) #f)
        (else (all-evaluated? (cdr ids)))))

(define (setvalue id value)
  (let ((old (cell-value id)))
    (set-cell-value! id value)
    (if (not (equal? old value))
        (for-each figure (cell-children id))
        'do-nothing)))


;;; Evaluating Expressions

(define (ss-eval expr)
  (cond ((number? expr) expr)
        ((quoted? expr) (quoted-value expr))
        ((id? expr) (cell-value expr))
        ((invocation? expr)
         (apply (get-function (car expr))
                (map ss-eval (cdr expr))))
        (else (error "Invalid expression:" expr))))

(define (quoted? expr)
  (or (string? expr)
      (and (list? expr) (equal? (car expr) 'quote))))

(define (quoted-value expr)
  (if (string? expr)
      expr
      (cadr expr)))

(define (invocation? expr)
  (list? expr))

(define (get-function name)
  (let ((result (assoc name *the-functions*)))
    (if (not result)
        (error "No such function: " name)
        (cadr result))))

(define *the-functions*
  (list (list '* *)
        (list '+ +)
        (list '- -)
        (list '/ /)
        (list 'abs abs)
        (list 'acos acos)
        (list 'asin asin)
        (list 'atan atan)
        (list 'ceiling ceiling)
        (list 'cos cos)
        (list 'count count)
        (list 'exp exp)
        (list 'expt expt)
        (list 'floor floor)
        (list 'gcd gcd)
        (list 'lcm lcm)
        (list 'log log)
        (list 'max max)
        (list 'min min)
        (list 'modulo modulo)
        (list 'quotient quotient)
        (list 'remainder remainder)
        (list 'round round)
        (list 'sin sin)
        (list 'sqrt sqrt)
        (list 'tan tan)
        (list 'truncate truncate)))

;;; Printing the Screen

(define (print-screen)
  (newline)
  (newline)
  (newline)
  (show-column-labels (id-column (screen-corner-cell-id)))
  (show-rows 20
             (id-column (screen-corner-cell-id))
             (id-row (screen-corner-cell-id)))
  (display-cell-name (selection-cell-id))
  (display ":  ")
  (show (cell-value (selection-cell-id)))
  (display-expression (cell-expr (selection-cell-id)))
  (newline)
  (display-decimal (selection-cell-id))
  (newline)
  (display "?? "))

(define (display-cell-name id)
  (display (number->letter (id-column id)))
  (display (id-row id)))

(define (show-column-labels col-number)
  (display "  ")
  (show-label 6 col-number)
  (newline))

(define (show-label to-go this-col-number)
  (cond ((= to-go 0) '())
        (else
          (display "  ----")
          (display (number->letter this-col-number))
          (display "----")
          (show-label (- to-go 1) (+ 1 this-col-number)))))

(define (show-rows to-go col row)
  (cond ((= to-go 0) 'done)
        (else
          (display (align row 2 0))
          (display " ")
          (show-row 6 col row)
          (newline)
          (show-rows (- to-go 1) col (+ row 1)))))

; (define (show-row to-go col row)
;   (cond ((= to-go 0) 'done)
;         (else
;           (display (if (selected-indices? col row) ">" " "))
;           (display-value (cell-value-from-indices col row))
;           (display (if (selected-indices? col row) "<" " "))
;           (show-row (- to-go 1) (+ 1 col) row))))

(define (show-row to-go col row)
   (cond ((= to-go 0) 'done)
         (else
           (display (if (selected-indices? col row) ">" " "))
           (display-value (cell-value-from-indices col row) col)
           (display (if (selected-indices? col row) "<" " "))
           (show-row (- to-go 1) (+ 1 col) row))))

(define (selected-indices? col row)
  (and (= col (id-column (selection-cell-id)))
       (= row (id-row (selection-cell-id)))))

; (define (display-value val)
;   (display (align (if (null? val) "" val) 9 2)))

(define (display-value val col)
  (display-val-helper val col 9))                   ; make cell wider when col > 26

(define (display-val-helper val col width)
  (display (align (if (null? val) "" val)
                  (if (> col 26) (+ 1 width) width)
                  (col-decimal-digit col))))                              ; get the digits after the decimal point from *column-decimal-digits*

(define (display-expression expr)
  (cond ((null? expr) (display '()))
        ((quoted? expr) (display (quoted-value expr)))
        ((word? expr) (display expr))
        ((id? expr)
         (display-cell-name expr))
        (else (display-invocation expr))))

(define (display-invocation expr)
  (display "(")
  (display-expression (car expr))
  (for-each (lambda (subexpr)
              (display " ")
              (display-expression subexpr))
            (cdr expr))
  (display ")"))

(define (display-decimal id)
  (display "decimal: ")
  (display (col-decimal-digit (id-column id))))

;;; Abstract Data Types

;; Special cells: the selected cell and the screen corner

(define *special-cells* (make-vector 2))

(define (selection-cell-id)
  (vector-ref *special-cells* 0))

(define (set-selection-cell-id! new-id)
  (vector-set! *special-cells* 0 new-id))

(define (screen-corner-cell-id)
  (vector-ref *special-cells* 1))

(define (set-screen-corner-cell-id! new-id)
  (vector-set! *special-cells* 1 new-id))


;; Cell names

(define (cell-name? expr)
  (and (word? expr)
       (letter-number? expr)))

(define (letter-number? wd)
  (and (letter? (cut-letter wd))
       (number? (cut-number wd))))

(define (cut-letter wd)
  (cond ((empty? wd) "")
        ((number? (first wd)) "")
        (else (word (first wd) (cut-letter (bf wd))))))

(define (cut-number wd)
  (cond ((empty? wd) "")
        ((not (number? (last wd))) "")
        (else (word (cut-number (bl wd)) (last wd)))))

(define (cell-name-column cell-name)
  (letter->number (cut-letter cell-name)))

(define (cell-name-row cell-name)
  (cut-number cell-name))

; (define (cell-name? expr)
;   (and (word? expr)
;        (letter? (first expr))
;        (number? (bf expr))))

; (define (cell-name-column cell-name)
;   (letter->number (first cell-name)))

; (define (cell-name-row cell-name)
;   (bf cell-name))

(define (cell-name->id cell-name)
  (make-id (cell-name-column cell-name)
           (cell-name-row cell-name)))

;; Cell IDs

;(define (make-id col row)
;  (list 'id col row))

(define (make-id col row)
  (vector col row))

;(define (id-column id)
;  (cadr id))

(define (id-column id)
  (vector-ref id 0))

;(define (id-row id)
;  (caddr id))

(define (id-row id)
  (vector-ref id 1))

;(define (id? x)
;  (and (list? x)
;       (not (null? x))
;       (equal? 'id (car x))))

(define (id? x)
  (and (vector? x)
       (= (vector-length x) 2)))

;; Cells

(define (make-cell)
  (vector '() '() '() '()))

(define (cell-value id)
  (vector-ref (cell-structure id) 0))

(define (cell-value-from-indices col row)
  (vector-ref (cell-structure-from-indices col row) 0))

(define (cell-expr id)
  (vector-ref (cell-structure id) 1))

(define (cell-parents id)
  (vector-ref (cell-structure id) 2))

(define (cell-children id)
  (vector-ref (cell-structure id) 3))

(define (set-cell-value! id val)
  (vector-set! (cell-structure id) 0 val))

(define (set-cell-expr! id val)
  (vector-set! (cell-structure id) 1 val))

(define (set-cell-parents! id val)
  (vector-set! (cell-structure id) 2 val))

(define (set-cell-children! id val)
  (vector-set! (cell-structure id) 3 val))

(define (cell-structure id)
  (global-array-lookup (id-column id)
                       (id-row id)))

(define (cell-structure-from-indices col row)
  (global-array-lookup col row))

; (define *the-spreadsheet-array* (make-vector *total-rows*))
(define *the-spreadsheet-array* (make-vector (* *total-cols* *total-rows*)))

; (define (global-array-lookup col row)
;   (if (and (<= row *total-rows*) (<= col *total-cols*))
;       (vector-ref (vector-ref *the-spreadsheet-array* (- row 1))
;                   (- col 1))
;       (error "Out of bounds")))

(define (global-array-lookup col row)
  (if (and (<= row *total-rows*) (<= col *total-cols*))
      (vector-ref *the-spreadsheet-array* (global-array-index col row))
      (error "Out of bounds")))

(define (global-array-index col row)
  (- (+ (* *total-cols* (- row 1)) col) 1))

; (define (init-array)
;   (fill-array-with-rows (- *total-rows* 1)))

; (define (fill-array-with-rows n)
;   (if (< n 0)
;       'done
;       (begin (vector-set! *the-spreadsheet-array* n (make-vector *total-cols*))
;              (fill-row-with-cells
;                (vector-ref *the-spreadsheet-array* n) (- *total-cols* 1))
;              (fill-array-with-rows (- n 1)))))

; (define (fill-row-with-cells vec n)
;   (if (< n 0)
;       'done
;       (begin (vector-set! vec n (make-cell))
;              (fill-row-with-cells vec (- n 1)))))

(define (init-array)
  (fill-array-with-cell *the-spreadsheet-array*
                        (- (vector-length *the-spreadsheet-array*) 1)))

(define (fill-array-with-cell vec index)
  (if (< index 0)
      'done
      (begin (vector-set! vec index (make-cell))
             (fill-array-with-cell vec (- index 1)))))

;;; Utility Functions

(define alphabet
  '#(a b c d e f g h i j k l m n o p q r s t u v w x y z
       aa ab ac ad ae af ag ah ai aj ak al am an ao ap aq ar as at au av aw ax ay az))

(define (letter? something)
  (and (word? something)
       (or (= 1 (count something))
           (= 2 (count something)))
       (vector-member something alphabet)))

(define (number->letter num)
  (vector-ref alphabet (- num 1)))

(define (letter->number letter)
  (+ (vector-member letter alphabet) 1))

(define (vector-member thing vector)
  (vector-member-helper thing vector 0))

(define (vector-member-helper thing vector index)
  (cond ((= index (vector-length vector)) #f)
        ((equal? thing (vector-ref vector index)) index)
        (else (vector-member-helper thing vector (+ 1 index)))))

(define (remdup lst)
  (cond ((null? lst) '())
        ((member (car lst) (cdr lst))
         (remdup (cdr lst)))
        (else (cons (car lst) (remdup (cdr lst))))))

(define (remove bad-item lst)
  (filter (lambda (item) (not (equal? item bad-item)))
          lst))

;;; Column decimal digit recorder

(define (init-decimal-digits vec digit index)  ; constructor
  (if (= index 0)
      vec
      (begin (vector-set! vec (- index 1) (vector (number->letter index) digit))
             (init-decimal-digits vec digit (- index 1)))))

(define *column-decimal-digits* (init-decimal-digits (make-vector *total-cols*)
                                                     2  ; initial decimal digit
                                                     *total-cols*))

(define (col-decimal-digit col)  ; selector
  (vector-ref (vector-ref *column-decimal-digits* (- col 1))
              1))

(define (set-col-decimal-digit! col digit)
  (vector-set! (vector-ref *column-decimal-digits* (- col 1))
               1
               digit))

;;; undo data --exercise 25.10

(define (init-undo-data data)
  (init-undo-data-helper data (- (vector-length data) 1)))

(define (init-undo-data-helper data index)
  (if (< index 0)
      data
      (begin (vector-set! data index null)
             (init-undo-data-helper data (- index 1)))))

;; *undo-cmd-data*

(define *undo-cmd-data* (vector null null))

;; *undo-put-data*

(define *undo-put-data*
  (init-undo-data (make-vector (* *total-rows* *total-cols*))))

;;; log undo command --exercise 25.10

(define (log-undo-cmd procedure arg-lst)
  (init-undo-data *undo-cmd-data*)
  (init-undo-data *undo-put-data*)
  (vector-set! *undo-cmd-data* 0 procedure)
  (vector-set! *undo-cmd-data* 1 arg-lst))

(define (log-undo-put expr cell-id)
  (let ((col (id-column cell-id))
        (row (id-row cell-id)))
    (vector-set! *undo-put-data*
                 (global-array-index col row)
                 (list expr cell-id))))