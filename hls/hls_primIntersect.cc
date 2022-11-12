typedef struct {
    float p0[3];
    float p1[3];
    float p2[3];
} myTriangle;

typedef struct {
    float o[3];
    float d[3];
    float dRcp[3];
    float mint;
    float maxt;
} Ray3f;

/*float dot(float x1, float y1, float z1, float x2, float y2, float z2) {
    return x1 * x2 + y1 * y2 + z1 * z2;
}

void cross(float x1, float y1, float z1, float x2, float y2, float z2,  float* res) {
    res[0] = (y1 * z2) - (y2 * z1);
    res[1] = (z1 * x2) - (z2 * x1);
    res[2] = (x1 * y2) - (x2 * y1);
}

void subP3f(Point3f triangle.p1, Point3f triangle.p0, Vector3f res) {
    res[0] = triangle.p1[0] - triangle.p0[0];
    res[1] = triangle.p1[1] - triangle.p0[1];
    res[2] = triangle.p1[2] - triangle.p0[2];
}*/

// bool Mesh::rayIntersect(uint32_t index, const Ray3f &ray, float &u, float &v, float &t) const {
bool rayIntersect(myTriangle triangle, Ray3f ray, float *u, float *v, float *t) {

#pragma HLS ARRAY_PARTITION variable=ray.o complete
#pragma HLS interface ap_none port=ray.o

#pragma HLS ARRAY_PARTITION variable=ray.d complete
#pragma HLS interface ap_none port=ray.d

#pragma HLS ARRAY_PARTITION variable=ray.dRcp complete
#pragma HLS interface ap_none port=ray.dRcp

#pragma HLS ARRAY_PARTITION variable=trianlge.p0 complete
#pragma HLS interface ap_none port=trianlge.p0

#pragma HLS ARRAY_PARTITION variable=trianlge.p1 complete
#pragma HLS interface ap_none port=trianlge.p1

#pragma HLS ARRAY_PARTITION variable=trianlge.p2 complete
#pragma HLS interface ap_none port=trianlge.p2
#pragma HLS pipeline
#pragma HLS interface ap_ctrl_none port=return
    // uint32_t i0 = m_F(0, index), i1 = m_F(1, index), i2 = m_F(2, index);
    // const Point3f triangle.p0 = m_V.col(i0), triangle.p1 = m_V.col(i1), triangle.p2 = m_V.col(i2);


    /* Find vectors for two edges sharing v[0] */
    float edge1[3], edge2[3];

    //Inlining subP3f
    edge1[0] = triangle.p1[0] - triangle.p0[0];
    edge1[1] = triangle.p1[1] - triangle.p0[1];
    edge1[2] = triangle.p1[2] - triangle.p0[2];

    edge2[0] = triangle.p2[0] - triangle.p0[0];
    edge2[1] = triangle.p2[1] - triangle.p0[1];
    edge2[2] = triangle.p2[2] - triangle.p0[2];

    /* Begin calculating determinant - also used to calculate U parameter */
    float pvec[3];

    //Inlining cross product
    pvec[0] = (ray.d[1] * edge2[2]) - (edge2[1] * ray.d[2]);
    pvec[1] = (ray.d[2] * edge2[0]) - (edge2[2] * ray.d[0]);
    pvec[2] = (ray.d[0] * edge2[1]) - (edge2[0] * ray.d[1]);

    /* If determinant is near zero, ray lies in plane of triangle */
    //Inline dot product
    float det = edge1[0] * pvec[0] + edge1[1] * pvec[1] + edge1[2] * pvec[2];

    if (det > -1e-8f && det < 1e-8f)
        return false;
    float inv_det = 1.0f / det;

    /* Calculate distance from v[0] to ray origin */
    float tvec[3];

    //Inlining subP3f
    tvec[0] = ray.o[0] - triangle.p0[0];
	tvec[1] = ray.o[1] - triangle.p0[1];
	tvec[2] = ray.o[2] - triangle.p0[2];

    /* Calculate U parameter and test bounds */
	//Inline dot product
	float u_tmp = (tvec[0] * pvec[0] + tvec[1] * pvec[1] + tvec[2] * pvec[2]) * inv_det;
    *u = u_tmp;

    if (u_tmp < 0.0 || u_tmp > 1.0)
        return false;

    /* Prepare to test V parameter */
    float qvec[3];
    //Inlining cross product
    qvec[0] = (tvec[1] * edge1[2]) - (edge1[1] * tvec[2]);
    qvec[1] = (tvec[2] * edge1[0]) - (edge1[2] * tvec[0]);
    qvec[2] = (tvec[0] * edge1[1]) - (edge1[0] * tvec[1]);

    /* Calculate V parameter and test bounds */
    float v_tmp = (ray.d[0] * qvec[0] + ray.d[1] * qvec[1] + ray.d[2] * qvec[2]) * inv_det;
    *v = v_tmp;

    if (v_tmp < 0.0 || u_tmp + v_tmp > 1.0)
        return false;

    /* Ray intersects triangle -> compute t */
    //Inline dot product
    float t_tmp = (edge2[0] * qvec[0] + edge2[1] * qvec[1] + edge2[2] * qvec[2]) * inv_det;
    *t = t_tmp;


    return t_tmp >= ray.mint && t_tmp <= ray.maxt;
}
