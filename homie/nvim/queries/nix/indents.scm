;; inherits: nix
;; extends

(
 function_expression (formals)
 @indent.begin
 (#set! indent.immediate 1)
)

(
 function_expression
 (formals "}" @indent.branch @indent.end)
)
