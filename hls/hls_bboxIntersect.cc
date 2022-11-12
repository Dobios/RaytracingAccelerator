#include <limits>
#include <inttypes.h>
#include <algorithm>

typedef struct {
	float o[3];
	float d[3];
	float dRcp[3];
	float mint;
	float maxt;
} Ray3f;

/// Check if a ray intersects a bounding box
bool rayIntersect(Ray3f ray, float min[3], float max[3]) {

#pragma HLS ARRAY_PARTITION variable=min complete
#pragma HLS interface ap_none port=min

#pragma HLS ARRAY_PARTITION variable=max complete
#pragma HLS interface ap_none port=max

#pragma HLS ARRAY_PARTITION variable=ray.o complete
#pragma HLS interface ap_none port=ray.o

#pragma HLS ARRAY_PARTITION variable=ray.d complete
#pragma HLS interface ap_none port=ray.d

#pragma HLS ARRAY_PARTITION variable=ray.dRcp complete
#pragma HLS interface ap_none port=ray.dRcp
#pragma HLS pipeline

#pragma HLS interface ap_ctrl_none port=return

    float nearT = -std::numeric_limits<float>::infinity();
    float farT = std::numeric_limits<float>::infinity();

    for (int i=0; i<3; i++) {
#pragma HLS unroll
        float origin = ray.o[i];
        float minVal = min[i], maxVal = max[i];

        if (ray.d[i] == 0) {
            if (origin < minVal || origin > maxVal)
                return false;
        } else {
            float t1 = (minVal - origin) * ray.dRcp[i];
            float t2 = (maxVal - origin) * ray.dRcp[i];

            if (t1 > t2)
                std::swap(t1, t2);

            nearT = std::max(t1, nearT);
            farT = std::min(t2, farT);

            if (!(nearT <= farT))
                return false;
        }
    }

    return ray.mint <= farT && nearT <= ray.maxt;
}

