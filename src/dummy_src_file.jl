"""
    dummy_project_function(x, y) → z
Dummy function for illustration purposes.
Performs operation:
```math
z = x + y
```
"""
function dummy_project_function(x, y)
    return x + y
end

function fakesim(a, b, v, method="linear")
    if method == "linear"
        r = @. a + b * v
    elseif method == "cubic"
        r = @. a * b * v^3
    end
    y = sqrt(b)
    return r, y
end