; Exercises 23.1-23.16

; Do not solve any of the following exercises by converting a vector to a list, using list procedures, and then converting the result back to a vector.

; 23.1 Write a procedure sum-vector that takes a vector full of numbers as its argument and returns the sum of all the numbers:

(sum-vector '#(6 7 8))
; 21

; solution:

(define (sum-vector vec)
  (sum-vec-helper vec (- (vector-length vec) 1)))

(define (sum-vec-helper vec index)
  (if (< index 0)
      0
      (+ (vector-ref vec index)
         (sum-vec-helper vec (- index 1)))))

; **********************************************************

; 23.2 Some versions of Scheme provide a procedure vector-fill! that takes a vector and anything as its two arguments. It replaces every element of the vector with the second argument, like this:

(define vec (vector 'one 'two 'three 'four))

vec
; #(one two three four)

(vector-fill! vec 'yeah)

vec
; #(yeah yeah yeah yeah)

; Write vector-fill! . (It doesn't matter what value it returns.)

; solution:

(define (vector-fill! vec ele)
  (vc-fill!-helper vec ele (- (vector-length vec) 1)))

(define (vc-fill!-helper vec ele index)
  (if (< index 0)
      vec
      (begin (vector-set! vec index ele)
             (vc-fill!-helper vec ele (- index 1)))))

; **********************************************************

; 23.3 Write a function vector-append that works just like regular append , but for vectors:

(vector-append '#(not a) '#(second time))
; #(not a second time)

(define (vector-append vec-a vec-b)
  (let ((index-a (- (vector-length vec-a) 1))
        (index-b (- (vector-length vec-b) 1))
        (vec-ab (make-vector (+ (vector-length vec-a)
                                (vector-length vec-b)))))
    (vec-append-helper vec-ab (- (vector-length vec-ab) 1)
                       vec-a index-a
                       vec-b index-b)))

(define (vec-append-helper vec-ab index-ab
                           vec-a index-a
                           vec-b index-b)
  (copy-vec vec-ab index-ab vec-b index-b)
  (copy-vec vec-ab (- index-ab (vector-length vec-b))
            vec-a index-a)
  vec-ab)

(define (copy-vec vec-out start vec-in index-in)
  (if (< index-in 0)
      'done
      (begin (vector-set! vec-out start
                          (vector-ref vec-in index-in))
             (copy-vec vec-out (- start 1)
                       vec-in (- index-in 1)))))

; **********************************************************

; 23.4 Write vector->list.

; solution:

(define (vector->list vec)
 (vec->lst-helper vec 0 (- (vector-length vec) 1)))

(define (vec->lst-helper vec index end)
  (if (= index end)
      (list (vector-ref vec index))
      (cons (vector-ref vec index)
            (vec->lst-helper vec (+ index 1) end))))

; **********************************************************

; 23.5 Write a procedure vector-map that takes two arguments, a function and a vector, and returns a new vector in which each box contains the result of applying the function to the corresponding element of the argument vector.

; solution:

(define (vector-map fun vec)
  (let ((vec-length (vector-length vec)))
    (vec-map-helper fun vec (make-vector vec-length) (- vec-length 1))))

(define (vec-map-helper fun vec new-vec index)
  (if (< index 0)
      new-vec
      (begin (vector-set! new-vec index
                          (fun (vector-ref vec index)))
             (vec-map-helper fun vec new-vec (- index 1)))))

; **********************************************************

; 23.6 Write a procedure vector-map! that takes two arguments, a function and a vector, and modifies the argument vector by replacing each element with the result of applying the function to that element. Your procedure should return the same vector.

; solution:

(define (vector-map! fun vec)
  (vec-map!-helper fun vec (- (vector-length vec) 1))
  vec)

(define (vec-map!-helper fun vec index)
  (if (< index 0)
      'done
      (begin (vector-set! vec index
                          (fun (vector-ref vec index)))
             (vec-map!-helper fun vec (- index 1)))))

; **********************************************************

; 23.7 Could you write vector-filter? How about vector-filter!? Explain the issues involved.

; answer:

; It's attainable to write vector-filter. Theoretically, We can filter the values of a vector and copy the filtered values into a new vecor. But it will be tricky to define the new vector since at first we don't know how many value containers we need when make-vector the new vecor. One possible strategy is copy the filtered values of the vector to a list and then convert the list to vector.

; It's not attainable to write vector-fiter! because a vector has a fixed number of boxes containing values. Instead of removing a value box from a vector, we can only change the value itself.

; **********************************************************

; 23.8 Modify the lap procedure to print “Car 34 wins!” when car 34 completes its 200th lap. (A harder but more correct modification is to print the message only if no other car has completed 200 laps.)

; ----------------------------------------------------------
(define *lap-vector* (make-vector 100))

(define (initialize-lap-vector index)
  (if (< index 0)
      'done
      (begin (vector-set! *lap-vector* index 0)
             (initialize-lap-vector (- index 1)))))

(define (lap car-number)
  (vector-set! *lap-vector*
               car-number
               (+ (vector-ref *lap-vector* car-number) 1))
  (vector-ref *lap-vector* car-number))
; ----------------------------------------------------------

; solution:

(define (lap car-number)
  (vector-set! *lap-vector*
               car-number
               (+ (vector-ref *lap-vector* car-number) 1))
  (let ((current-lap (vector-ref *lap-vector* car-number)))
    (if (= current-lap 200)
        (begin (display "Car ")
               (display car-number)
               (show " wins!"))
        (vector-ref *lap-vector* car-number))))

; better-solution:

(define (lap-v2 car-number)
  (vector-set! *lap-vector*
               car-number
               (+ (vector-ref *lap-vector* car-number) 1))
  (let ((current-lap (vector-ref *lap-vector* car-number)))
    (if (and (= current-lap 200)
             (if-first-complete? car-number *lap-vector* (- (vector-length *lap-vector*) 1)))
        (begin (display "Car ")
               (display car-number)
               (show " wins!"))
        (vector-ref *lap-vector* car-number))))

(define (if-first-complete? car-number recorder index)
  (if (< index 0)
      car-number
      (if (or (= index car-number)
              (< (vector-ref recorder index) 200))
          (if-first-complete? car-number recorder (- index 1))
          #f)))

; **********************************************************

; 23.9 Write a procedure leader that says which car is in the lead right now.

; solution:

(define (leader recorder)
  (leader-helper recorder (- (vector-length recorder) 2) (- (vector-length recorder) 1)))

(define (leader-helper recorder rest lead-car)
  (if (< rest 0)
      lead-car
      (if (> (vector-ref recorder rest) (vector-ref recorder lead-car))
          (leader-helper recorder (- rest 1) rest)
          (leader-helper recorder (- rest 1) lead-car))))

; **********************************************************

; 23.10 Why doesn’t this solution to Exercise 23.9 work?

; (define (leader)
;   (leader-helper 0 1))

; (define (leader-helper leader index)
;   (cond ((= index 100) leader)
;         ((> (lap index) (lap leader))
;          (leader-helper index (+ index 1)))
;         (else (leader-helper leader (+ index 1)))))

; answer: The leader defined above doesn't work because the leader-helper may repeadly apply procedure lap on leader car and make it bigger than other cars. Procedure lap should be replaced by procedure vector-ref to check the cars's current laps instead of changing its current laps.

; **********************************************************

; 23.11 In some restaurants, the servers use computer terminals to keep track of what each table has ordered. Every time you order more food, the server enters your order into the computer. When you’re ready for the check, the computer prints your bill.

; You’re going to write two procedures, order and bill. Order takes a table number and an item as arguments and adds the cost of that item to that table’s bill. Bill takes a table number as its argument, returns the amount owed by that table, and resets the table for the next customers. (Your order procedure can examine a global variable *menu* to find the price of each item.)

(order 3 'potstickers)
(order 3 'wor-won-ton)
(order 5 'egg-rolls)
(order 3 'shin-shin-special-prawns)

(bill 3)
; 13.85

(bill 5)
; 2.75

; solution:

(define *menu* (list '(egg-rolls 2.75) '(potstickers 5) '(wor-won-ton 3)             ; create *menu* a-list
                     '(shin-shin-special-prawns 5.85) '(fish-n-chips 4.5)
                     '(beef-pie 1.2) '(newyorker-pizza 9.9) '(fried-dumplings 12)))

(define *table-bills* (make-vector 10))    ; create ten-table *table-bills* vector

(define (initialize-table-bills index)     ; define initialize-table-bills to initialize the whole *table-bills* vector with 0
  (if (< index 0)
      'done
      (begin (vector-set! *table-bills* index 0)
             (initialize-table-bills (- index 1)))))

(initialize-table-bills 9)                 ; Initialize the 10 table bills, here the table numbers are from 0 to 9

(define (order table dish)                 ; define procedure order
  (vector-set! *table-bills* table
               (+ (vector-ref *table-bills* table)
                  (cadr (assoc dish *menu*))))
  (show "Order is registered"))

(define (bill table)                       ; define procedure bill
  (show (vector-ref *table-bills* table))
  (vector-set! *table-bills* table 0))

; **********************************************************

; 23.12 Rewrite selection sort (from Chapter 15) to sort a vector. This can be done in a way similar to the procedure for shuffling a deck: Find the smallest element of the vector and exchange it (using vector-swap! ) with the value in the first box. Then find the smallest element not including the first box, and exchange that with the second box, and so on. For example, suppose we have a vector of numbers:

#(23 4 18 7 95 60)

; Your program should transform the vector through these intermediate stages:

#(4 23 18 7 95 60)   ; exchange 4 with 23
#(4 7 18 23 95 60)   ; exchange 7 with 23
#(4 7 18 23 95 60)   ; exchange 18 with itself
#(4 7 18 23 95 60)   ; exchange 23 with itself
#(4 7 18 23 60 95)   ; exchange 60 with 95

; solution:

(define (vector-sort! vec)
  (vec-sort!-helper vec 0))

(define (vec-sort!-helper vec index)
  (if (= index (- (vector-length vec) 1))
      vec
      (begin (vector-swap! vec (earliest-ele vec (+ index 1) index) index)
             (vec-sort!-helper vec (+ index 1)))))

(define (vector-swap! vector index1 index2)
  (let ((temp (vector-ref vector index1)))
    (vector-set! vector index1 (vector-ref vector index2))
    (vector-set! vector index2 temp)))

(define (earliest-ele vec start earliest)
  (if (> start (- (vector-length vec) 1))
      earliest
      (if (< (vector-ref vec start) (vector-ref vec earliest))
          (earliest-ele vec (+ start 1) start)
          (earliest-ele vec (+ start 1) earliest))))

; **********************************************************

; 23.13 Why doesn’t this work?

; (define (vector-swap! vector index1 index2)
;   (vector-set! vector index1 (vector-ref vector index2))
;   (vector-set! vector index2 (vector-ref vector index1)))

; answer: The procedure above doesn't work because the value at index1 has already been replaced with the value at index2 before we try to replace the value at index2 with the value of index1. As a result index1 and index2 will have the same value--the original index2 value.

; **********************************************************

; 23.14 Implement a two-dimensional version of vectors. (We’ll call one of these structures a matrix.) The implementation will use a vector of vectors. For example, a three-by-five matrix will be a three-element vector, in which each of the elements is a five-element vector. Here’s how it should work:

(define m (make-matrix 3 5))

(matrix-set! m 2 1 '(her majesty))

(matrix-ref m 2 1)
; (HER MAJESTY)

; solution:

(define (make-matrix x y)
  (make-matrix-helper (make-vector x) (- x 1) y))

(define (make-matrix-helper vec index y)
  (if (< index 0)
      vec
      (begin (vector-set! vec index (make-vector y))
             (make-matrix-helper vec (- index 1) y))))

(define (matrix-set! mtrix index-x index-y value)
  (vector-set! (vector-ref mtrix index-x) index-y value))

(define (matrix-ref mtrix index-x index-y)
  (vector-ref (vector-ref mtrix index-x) index-y))

; **********************************************************

; 23.15 Generalize Exercise 23.14 by implementing an array structure that can have any number of dimensions. Instead of taking two numbers as index arguments, as the matrix procedures do, the array procedures will take one argument, a list of numbers. The number of numbers is the number of dimensions, and it will be constant for any particular array. For example, here is a three-dimensional array (4 × 5 × 6):

(define a1 (make-array '(4 5 6)))

(array-set! a1 '(3 2 3) '(the end))

; solution:

(define (make-array lst)
  (let ((vec (make-vector (car lst))))
    (make-array-helper vec (- (vector-length vec) 1) (cdr lst))))

(define (make-array-helper array index lst)
  (if (null? lst)
      array
      (begin (forest-array array index (car lst))
             (make-array-helper array index (cdr lst)))))

(define (forest-array array index end-vec-num)
  (cond ((< index 0) array)
        ((unspecified-child? array index) (begin (vector-set! array index
                                                           (make-vector end-vec-num))
                                              (forest-array array (- index 1) end-vec-num)))
        (else (begin (let ((deep-array (vector-ref array index)))
                       (forest-array deep-array (- (vector-length deep-array) 1) end-vec-num))
                     (forest-array array (- index 1) end-vec-num)))))

(define (unspecified-child? vec index)
  (if (vector? (vector-ref vec index))
      #f
      #t))


(define (array-ref array index-lst)
  (array-ref-helper array (reverse index-lst)))

(define (array-ref-helper array reverse-index-lst)
  (if (null? (cdr reverse-index-lst))
      (vector-ref array (car reverse-index-lst))
      (vector-ref (array-ref-helper array (cdr reverse-index-lst)) (car reverse-index-lst))))


(define (array-set! array index-list value)
  (vector-set! (array-ref array (but-lst-last index-list))
               (lst-last index-list) value))

(define (lst-last lst)
  (if (null? (cdr lst))
      (car lst)
      (lst-last (cdr lst))))

(define (but-lst-last lst)
  (if (null? (cdr lst))
      '()
      (cons (car lst) (but-lst-last (cdr lst)))))

; **********************************************************

; 23.16 We want to reimplement sentences as vectors instead of lists.

; (a) Write versions of sentence, empty?, first, butfirst, last, and butlast that use vectors. Your selectors need only work for sentences, not for words.

(sentence 'a 'b 'c)
; #(A B C)

(butfirst (sentence 'a 'b 'c))
; #(B C)

; (You don’t have to make these procedures work on lists as well as vectors!)

; solution:

(define (sentence . wds)
  (apply vector wds))


(define (empty? vec-sent)
  (empty?-helper vec-sent (- (vector-length vec-sent) 1)))

(define (empty?-helper vec-sent index)
  (cond ((< index 0) #t)
        ((not (word? (vector-ref vec-sent index)))
         (empty?-helper vec-sent (- index 1)))
        (else #f)))


(define (first vec-sent)
  (vector-ref vec-sent 0))


(define (butfirst vec-sent)
  (let ((index (- (vector-length vec-sent) 1)))
    (butfirst-helper vec-sent index
                     (make-vector index) (- index 1))))

(define (butfirst-helper vec-sent index new-vec-sent new-index)
  (if (= index 0)
      new-vec-sent
      (begin (vector-set! new-vec-sent new-index (vector-ref vec-sent index))
             (butfirst-helper vec-sent (- index 1) new-vec-sent (- new-index 1)))))

(define (last vec-sent)
  (vector-ref vec-sent (- (vector-length vec-sent) 1)))


(define (butlast vec-sent)
  (let ((index (- (vector-length vec-sent) 2)))
    (butlast-helper  vec-sent index
                     (make-vector (+ index 1)) index)))

(define (butlast-helper vec-sent index new-vec-sent new-index)
  (if (< index 0)
      new-vec-sent
      (begin (vector-set! new-vec-sent new-index (vector-ref vec-sent index))
             (butlast-helper vec-sent (- index 1) new-vec-sent (- new-index 1)))))

; **********************************************************

; (b) Does the following program still work with the new implementation of sentences? If not, fix the program.

(define (praise stuff)
  (sentence stuff '(is good)))

; solution:

(define (sentence . stuff)
  (apply vector (filter-to-wd stuff)))

(define (filter-to-wd lst)
  (cond ((null? lst) '())
        ((list? (car lst)) (append (car lst) (filter-to-wd (cdr lst))))
        (else (cons (car lst) (filter-to-wd (cdr lst))))))

; **********************************************************

; (c) Does the following program still work with the new implementation of sentences? If not, fix the program.

(define (praise stuff)
  (sentence stuff 'rules!))

; answer: it works.

; **********************************************************

; (d) Does the following program still work with the new implementation of sentences? If not, fix the program. If so, is there some optional rewriting that would improve its performance?

(define (item n sent)
  (if (= n 1)
      (first sent)
      (item (- n 1) (butfirst sent))))

; answer: It works.
; Since procedure butfirst includes make-vector which is not a cosntant operation and sent is essentially a vector, we can improve item's performance with constant operation vector-ref.

; solution:

(define (item n sent)
  (vector-ref sent (- n 1)))

; **********************************************************

; (e) Does the following program still work with the new implementation of sentences? If not, fix the program. If so, is there some optional rewriting that would improve its performance?

(define (every fn sent)
  (if (empty? sent)
      sent
      (sentence (fn (first sent))
                (every fn (butfirst sent)))))

; answer: The program doesn't work because the new sentence procedure only accepts words and list sentences as its arguments, not including vectors.

; solution:

(define (every fn sent)
  (let ((sent-length (vector-length sent)))
    (every-helper fn sent (make-vector sent-length) (- sent-length 1))))

(define (every-helper fn sent new-sent index)
  (if (< index 0)
      new-sent
      (begin (vector-set! new-sent index (fn (vector-ref sent index)))
             (every-helper fn sent new-sent (- index 1)))))

; **********************************************************

; (f) In what ways does using vectors to implement sentences affect the speed of the selectors and constructor? Why do you think we chose to use lists?

; answer: By using vectors to implement sentences, only selectos like first, last and item are cosntant operations since they only use constant vector operations. Other vector sentence selectors and constructors all take more time for more elements.

; The reason to use lists to implement sentencs in the book may be it's more flexible and efficient to edit a list sentence with cons, car, cdr and null? while to edit a vector sentence is more likely to use non-constant operation make-vector.
