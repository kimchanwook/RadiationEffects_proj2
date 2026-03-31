function Cexact = exact_uniform_annealing_2d(C0, kAnn, t)
Cexact = C0 .* exp(-kAnn .* t);
end
