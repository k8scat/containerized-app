import request from './request';

export const getHitokoto = () => {
    return request.get('/hitokoto')
}
