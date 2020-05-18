! this subroutine fills in the entries of the line/point distance matrix where the lines are interpreted as segments
! of a great circle over the surface of the unit sphere centered at the origin. The matrix is in a sparse format; entries are
! only populated when the closest distance between line/point pairs is less than the point's range.
! the number of entries must be known beforehand (via a call to LKTomGridSphereCount) to make sure the right amount of
! space is allocated for the matrix entries.

subroutine LKTomGridSphere(points, nPoints, lines, nLines, ranges, &
        rangeReps, nRanges, ind, entries, completions, nEntries)
    implicit none
    integer, parameter :: dim = 3
    integer, intent(in) :: nPoints, nLines, nRanges, rangeReps(nRanges), nEntries
    integer :: rangeStarts(nRanges), outputIdx, localOutputIdx, rangeIdx, lineIdx, dimIdx, pointIdx
    integer, intent(out) :: ind(2, nEntries)

    double precision, intent(in) :: points(dim, nPoints), lines(2*dim, nLines), ranges(nRanges)
    double precision :: pointVec(dim), range, v1(dim), v2(dim), v1Perp(dim), v2Perp(dim), normal(dim)
    double precision :: dotProd, projRange, dist, compStart, compStop
    double precision, intent(out) :: entries(nEntries), completions(2, nEntries)

    !for each line
    !compute cross product of the line's endpoints to get unit normal vector
    !for each range
    !take the sine of the range to get the euclidean distance in the direction of the normal vector that guarantees
    !that a line misses a point
    !for each point
    !take the inner product of that point with the normal vector; if its absolute value is greater than the
    !sine of the current range, continue (the line must miss the point)
    !otherwise, check to see if the point misses the line segment:
    !if the arccos of the inner product of the point with either of the two line points is less than the range, the
    !point is in range of that endpoint; otherwise, the circle must either touch only the interior of the line or not
    !touch the line at all. We test this by projecting the point onto the vectors perpendicular to L1 and L2,
    !pointing inward in the plane of L1 and L2. if either projection is negative, the point must be closer to
    !an endpoint than any other point on the line segment, so it doesn't touch; otherwise, the point must be within
    !range of the line, and on the section of the sphere where its closer point to the line segment is on the
    !interior, so it must touch the line.

    !pseudocode:
    !check if circle is too far away from whole line
    !check if circle is close enough to an endpoint
    !check if circle is along the interior of the line segment

    !
    outputIdx = 1
    ind(:,:) = -1
    entries(:) = -5.1
    completions(1,:) = 0
    completions(2,:) = 1

    ! determining which points will have which ranges
    rangeStarts(1) = 0
    do rangeIdx = 1, (nRanges-1)
        rangeStarts(rangeIdx+1) = rangeStarts(rangeIdx) + rangeReps(rangeIdx)
    enddo

    !$omp parallel private(pointVec, v1, v2, dotProd, v1Perp, v2Perp, normal, range, projRange, localOutputIdx, dist, &
    !$omp compStart, compStop)
    !$omp do
    do lineIdx = 1, nLines
        v1 = lines(:dim, lineIdx)
        v2 = lines(dim+1:, lineIdx)
        dotProd = sum(v1 * v2)
        v1Perp = v2 - dotProd * v1
        v2Perp = v1 - dotProd * v2
        normal(1) = v1(2) * v2(3) - v1(3) * v2(2)
        normal(2) = v1(3) * v2(1) - v1(1) * v2(3)
        normal(3) = v1(1) * v2(2) - v1(2) * v2(1)
        normal = normal / sqrt(sum(normal * normal))
        do rangeIdx = 1, nRanges
            range = ranges(rangeIdx)
            projRange = sin(range)
            do pointIdx = (rangeStarts(rangeIdx)+1), (rangeStarts(rangeIdx) + rangeReps(rangeIdx))
                pointVec = points(:, pointIdx)
                if (cos(range) > 0 .and. abs(sum(pointVec * normal)) > projRange) then
                    cycle
                endif
                dist = asin(abs(sum(pointVec * normal)))
                !check 2
                if (acos(sum(v1 * pointVec)) < range .or. acos(sum(v2 * pointVec)) < range) then
                    !$omp atomic capture
                    localOutputIdx = outputIdx
                    outputIdx = outputIdx + 1
                    !$omp end atomic
                    ind(1, localOutputIdx) = lineIdx
                    ind(2, localOutputIdx) = pointIdx
                    entries(localOutputIdx) = dist / range
                    compStart = 0;
                    compStop = 1;
                    if (acos(sum(v1 * pointVec)) < range) then
                        if (sum(v1Perp * pointVec) > 0) then
                            completions(1, localOutputIdx) = 0.5 * (1 - acos(sum(v1*pointVec) / cos(dist)) / &
                                    acos(cos(range) / cos(dist)))
                        else
                            completions(1, localOutputIdx) = 0.5 * (1 + acos(sum(v1*pointVec) / cos(dist)) / &
                                    acos(cos(range) / cos(dist)))
                        endif
                    endif
                    if (acos(sum(v2 * pointVec)) < range) then
                        if (sum(v2Perp * pointVec) > 0) then
                            completions(2, localOutputIdx) = 0.5 * (1 + acos(sum(v2*pointVec) / cos(dist)) / &
                                    acos(cos(range) / cos(dist)))
                        else
                            completions(2, localOutputIdx) = 0.5 * (1 - acos(sum(v2*pointVec) / cos(dist)) / &
                                    acos(cos(range) / cos(dist)))
                        endif
                    endif
                    cycle
                endif

                !check 3
                if (sum(v1Perp * pointVec) > 0 .and. sum(v2Perp * pointVec) > 0) then
                    !$omp atomic capture
                    localOutputIdx = outputIdx
                    outputIdx = outputIdx + 1
                    !$omp end atomic
                    ind(1, localOutputIdx) = lineIdx
                    ind(2, localOutputIdx) = pointIdx
                    entries(localOutputIdx) = dist / range
                endif
            enddo
        enddo
    enddo
    !$omp end do
    !$omp end parallel

end subroutine LKTomGridSphere