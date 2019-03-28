using JetBrains.Annotations;
using System.Collections.Generic;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.Animations;
using Random = Unity.Mathematics.Random;


public class VectorFieldGenerator : MonoBehaviour
{


    [Header("Vector Field params")]
    [SerializeField] private Vector3Int _size;
    [SerializeField] private FilterMode _filterMode;
    [SerializeField] private float _scale;
    [SerializeField] private bool _isSimplex;
    [SerializeField] private float _step = 8.0f;

    [Header("Gradient")]
    [SerializeField] private float _epsilon;
    [SerializeField] private bool _isDivergenceFree;
    [SerializeField] private bool _isBoundary;
    [SerializeField] private Vector3 _borders;

    [Header("Gizmos")]
    [SerializeField] private float _vectorScale;
    [SerializeField] private Vector3 _offset;
    [SerializeField] private float _pointScale;

	[Header("Renderer")]
    [SerializeField] private Transform _rendererTransform;
    [SerializeField] private int _instances;
    [SerializeField] private float _speedFactor;
    [SerializeField] private float _maxSpeed;
    [SerializeField] private ForceMode _forceMode;

    [Header("Compute shader")]
    [SerializeField] private ComputeShader _updater;

    private Vector4[] _vectorField;
    private Vector3 _velocity;
    private float _speed;
    private List<Transform> _renderers;
    private Vector3[] _positions;
    private Vector2[] _scales;
    private ComputeBuffer _positionsBuffer;
    private ComputeBuffer _scaleBuffer;



    private Texture2D GeneratePerlinTexture(Vector2Int size)
    {
        Texture2D texture = new Texture2D(size.x, size.y)
        {
            hideFlags = HideFlags.HideAndDontSave,
            filterMode = _filterMode,
            wrapMode = TextureWrapMode.Repeat
        };

        Color[] colors = new Color[texture.width * texture.height];
        _vectorField = new Vector4[texture.width * texture.height];
        Color c = new Color();

        for (int i = 0; i < colors.Length; i++)
        {
            Vector4 noise = new Vector4();

            int x = i % texture.width;
            int y = i / texture.width;
            

            if (_isSimplex)
            {
                noise = SimplexNoise3d.snoise(new float3(x * _scale + Time.time * 0.3f, y * _scale, Time.time * 0.6f));
            }
            else
            {
                //noise = Mathf.PerlinNoise(x * _scale, y * _scale);
            }

            float color = noise.w * 0.5f + 0.5f;
            c.r = color;
            c.g = color;
            c.b = color;

            colors[colors.Length - 1 - i] = c;
            _vectorField[i] = noise;
            if (_isDivergenceFree)
            {
                _vectorField[i] = Vector3.Cross(_vectorField[i], Vector3.forward);
            }
        }
        
        texture.SetPixels(colors);
        texture.Apply();

        return texture;
    }


    private Vector2[] FindVectorField(IList<Color> colors, float step)
    {
        Vector2[] v = new Vector2 [colors.Count / (int)(step)];

        for (int i = 0; i < colors.Count; i += (int)(step))
        {
            int x = i % _size.x; // 0
            int y = i / _size.x; // 3
        
            float r = (x + _epsilon) + y * _size.x; // 1 + 3 * 4 = 13
            float l = (x - _epsilon) + y * _size.x; // -1 + 3 * 4 = 11
            float u = x + (y + _epsilon) * _size.x; // 16
            float d = x + (y - _epsilon) * _size.x; // 8

            int index = v.Length - 1 - i / (int)(step);
            try
            {
                v[index] = new Vector2(
                    colors[(int)Mathf.Min(colors.Count - 1, r)].r - colors[(int)Mathf.Max(0, l)].r,
                    colors[(int)Mathf.Min(colors.Count - 1, u)].r - colors[(int)Mathf.Max(0, d)].r);

                if (_isDivergenceFree)
                {
                    v[index] = Vector3.Cross(v[index], Vector3.forward);
                }
            }
            catch
            {
                Debug.Log($"For i = {i} it computes index = {index}");
            }
        }

        return v;
    }


    private void Start()
    {
	    _renderers = new List<Transform>();
		_positions = new Vector3[_instances + 1];
		_scales = new Vector2[_instances + 1];

		_renderers.Add(_rendererTransform);
		_positions[0] = _rendererTransform.position;

		float lifetime = 2.0f;

		_scales[0] = new Vector2(_rendererTransform.localScale.x, lifetime);
		_rendererTransform.parent = transform;
			var ps = _rendererTransform.GetComponentInChildren<ParticleSystem>();
			var main = ps.main;
		for (int i = 1; i < _instances + 1; i++)
		{
			main.startColor = UnityEngine.Random.ColorHSV(0, 0.9f, 0.8f, 0.9f, 0.4f, 0.5f);

			Transform t = Instantiate(_rendererTransform.gameObject, UnityEngine.Random.insideUnitSphere,
				Quaternion.identity, transform).transform;

			_renderers.Add(t);
			_positions[i] = t.position;

			float scale = UnityEngine.Random.value * t.localScale.x;
			_scales[i] = new Vector2(scale, lifetime);
			t.localScale = scale * Vector3.one;

		}

		UpdateBuffers();
    }


    private void UpdateBuffers()
    {
		ReleaseBuffers();

	    _positionsBuffer = new ComputeBuffer(_renderers.Count, 12);
	    _positionsBuffer.SetData(_positions);
	    _scaleBuffer = new ComputeBuffer(_renderers.Count, 8);
	    _scaleBuffer.SetData(_scales);
	}


    private void Update()
    {
	    _speed = Input.GetAxis("Horizontal") * _speedFactor;

		UpdatePositions(_speed);

	    //foreach (Transform rt in _renderers)
	    //{
		   // TranslateRenderer(rt, _speed);
	    //}
	}


    private void OnDestroy()
    {
	    ReleaseBuffers();
    }


    private void UpdatePositions(float speed)
    {
	    if (_positionsBuffer == null || _scaleBuffer == null)
	    {
			UpdateBuffers();
	    }

	    int updater = _updater.FindKernel("Update");

		_updater.SetBuffer(updater, "PositionBuffer", _positionsBuffer);
		_updater.SetBuffer(updater, "ScaleBuffer", _scaleBuffer);

		_updater.SetVector("_offset", _offset);
		_updater.SetVector("_size", (Vector3)_size);
		_updater.SetVector("_borders", _borders);
		_updater.SetFloat("_scale", _scale);
		_updater.SetFloat("_speed", speed);
		_updater.SetFloat("_maxSpeed", _maxSpeed);
		
		_updater.Dispatch(updater, _positions.Length / 1024, 1, 1);

		_positionsBuffer.GetData(_positions);
		_scaleBuffer.GetData(_scales);

		for (int i = 0; i < _renderers.Count; i++)
		{
			_renderers[i].position = _positions[i];
			_renderers[i].localScale = Vector3.one * _scales[i].x;
		}
    }


    private void ReleaseBuffers()
    {
		_positionsBuffer?.Release();
		_scaleBuffer?.Release();
    }


    private void TranslateRenderer(Transform rendererTransform, float speed)
    {
	    Vector3 position = rendererTransform.position;

	    Vector3 grad = SimplexNoise3d.snoise(new float3(
		    position.x * _scale + Time.time * _offset.x,
		    position.y * _scale + Time.time * _offset.y,
		    position.z * _scale + Time.time * _offset.z)
	    ).xyz;

	    Vector3 grad1 = SimplexNoise3d.snoise(new float3(
			position.x * _scale + Time.time * _offset.x,
			position.y * _scale + Time.time * _offset.y,
			position.z * _scale + Time.time * _offset.z
		) + new float3(15.3f, 13.1f, 17.4f)).xyz;

	    grad = Vector3.Cross(grad, grad1);

	    if (_isBoundary)
	    {
		    if (position.x >= _size.x - _borders.x)
		    {
			    grad = Vector3.Lerp(grad, Vector3.zero - position, position.x - (_size.x - _borders.x));
		    }
		    else if (position.x <= -_size.x + _borders.x)
		    {
			    grad = Vector3.Lerp(grad, Vector3.zero - position, -position.x - (_size.x - _borders.x));
		    }
		    if (position.y <= -_size.y + _borders.y)
		    {
			    grad = Vector3.Lerp(grad, Vector3.zero - position, -position.y - (_size.y - _borders.y));
		    }
		    else if (position.y >= _size.y - _borders.y)
		    {
			    grad = Vector3.Lerp(grad, Vector3.zero - position, position.y - (_size.y - _borders.y));
		    }
		    if (position.z <= -_size.z + _borders.z)
		    {
			    grad = Vector3.Lerp(grad, Vector3.zero - position, -position.z - (_size.z - _borders.z));
		    }
		    else if (position.z >= _size.z - _borders.z)
		    {
			    grad = Vector3.Lerp(grad, Vector3.zero - position, position.z - (_size.z - _borders.z));
		    }
	    }

	    _velocity = Vector3.ClampMagnitude(grad * speed, _maxSpeed);

	    rendererTransform.Translate(_velocity * Time.deltaTime);
	}


    private void OnDrawGizmosSelected()
    {
	    int i = 0;
	    for (float x = -_size.x; x < _size.x; x += _step)
	    {
		    for (float y = -_size.y; y < _size.y; y += _step)
		    {
			    for (float z = -_size.z; z < _size.z; z += _step)
			    {
				    Gizmos.color = Color.red;
				    if (i++ > 1000000)
				    {
					    return;
				    }

				    Vector3 position = new Vector3(x, y, z);

					Vector3 grad = SimplexNoise3d.snoise(new float3(
						position.x * _scale + Time.time * _offset.x,
						position.y * _scale + Time.time * _offset.y,
						position.z * _scale + Time.time * _offset.z)
					).xyz;

					Vector3 grad1 = SimplexNoise3d.snoise(new float3(
						position.x * _scale + Time.time * _offset.x,
						position.y * _scale + Time.time * _offset.y,
						position.z * _scale + Time.time * _offset.z
					) + new float3(15.3f, 13.1f, 17.4f)).xyz;

					if (_isDivergenceFree)
				    {
					    grad = Vector3.Cross(grad, grad1);
					}

					if (_isBoundary)
					{
					    if (position.x >= _size.x - _borders.x)
					    {
						    Gizmos.color = Color.Lerp(Color.red, Color.yellow, position.x - (_size.x - _borders.x));
							grad = Vector3.Lerp(grad, Vector3.zero - position, position.x - (_size.x - _borders.x));
					    }
						else if (position.x <= -_size.x + _borders.x)
						{
						    Gizmos.color = Color.Lerp(Color.red, Color.yellow, -position.x - (_size.x - _borders.x));
							grad = Vector3.Lerp(grad, Vector3.zero - position, -position.x - (_size.x - _borders.x));
						}
						if (position.y <= -_size.y + _borders.y)
						{
						    Gizmos.color = Color.Lerp(Color.red, Color.yellow, -position.y - (_size.y - _borders.y));
							grad = Vector3.Lerp(grad, Vector3.zero - position, -position.y - (_size.y - _borders.y));
						}
						else if (position.y >= _size.y - _borders.y)
						{
						    Gizmos.color = Color.Lerp(Color.red, Color.yellow, position.y - (_size.y - _borders.y));
							grad = Vector3.Lerp(grad, Vector3.zero - position, position.y - (_size.y - _borders.y));
						}
						if (position.z <= -_size.z + _borders.z)
						{
						    Gizmos.color = Color.Lerp(Color.red, Color.yellow, -position.z - (_size.z - _borders.z));
							grad = Vector3.Lerp(grad, Vector3.zero - position, -position.z - (_size.z - _borders.z));
						}
						else if (position.z >= _size.z - _borders.z)
						{
						    Gizmos.color = Color.Lerp(Color.red, Color.yellow, position.z - (_size.z - _borders.z));
							grad = Vector3.Lerp(grad, Vector3.zero - position, position.z - (_size.z - _borders.z));
						}
					}

					Gizmos.DrawRay(position, grad * _vectorScale);
			    }
		    }
	    }

		Gizmos.color = Color.cyan;
	    Gizmos.DrawRay(_rendererTransform.position, _velocity * _vectorScale * 50f);
		//Gizmos.color = Color.blue;
	    //Gizmos.DrawRay(_rendererTransform.position, _rendererTransform.velocity * _vectorScale * 100);
	}


}
