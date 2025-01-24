import { Canvas } from '@react-three/fiber'
import { CameraComp } from './Camera'
import { TransformComp } from './Transform'

export const ThreeComp = () => {
    return (
        <Canvas style={{zIndex:1}}>
            <CameraComp />
            <TransformComp />
        </Canvas>
    )
}