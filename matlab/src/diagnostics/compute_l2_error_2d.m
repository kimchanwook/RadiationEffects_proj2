function err = compute_l2_error_2d(Fnum, Fexact, gridData)
diffField = Fnum - Fexact;
err = sqrt(sum(diffField.^2, 'all') * gridData.dx * gridData.dy);
end
