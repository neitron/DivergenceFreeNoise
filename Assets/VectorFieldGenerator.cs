using JetBrains.Annotations;
using System.Collections.Generic;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.Animations;


public class VectorFieldGenerator : MonoBehaviour
{


    [Header("Vector Field params")]
    [SerializeField] private Vector2Int _size;
    [SerializeField] private FilterMode _filterMode;
    [SerializeField] private float _scale;
    [SerializeField] private bool _isSimplex;
    [SerializeField] private float _step = 8.0f;

    [Header("Gradient")]
    [SerializeField] private float _epsilon;
    [SerializeField] private bool _isDivergenceFree;
    [SerializeField] private bool _isBoundary;
    [SerializeField] private Rect _borders;

    [Header("Gizmos")]
    [SerializeField] private float _vectorScale;
    [SerializeField] private Vector3 _offset;
    [SerializeField] private float _pointScale;

	[Header("Renderer")]
    [SerializeField] private Transform _rendererTransform;
    [SerializeField] private float _speedFactor;
    [SerializeField] private ForceMode _forceMode;
	

    private Vector4[] _vectorField;
    private Vector3 _velocity;
    private float _speed;


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
            //if (x > texture.width * 0.95f) // TODO: remove
            //{
            //    noise = 0;
            //}
            //else if (x < texture.width * 0.05f) // TODO: remove
            //{
            //    noise = 0;
            //}
            //if (y > texture.height * 0.95f) // TODO: remove
            //{
            //    noise = 0;
            //}
            //else if (y < texture.height * 0.05f) // TODO: remove
            //{
            //    noise = 0;
            //}

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

	
    private void Update()
    {
	    _speed = Input.GetAxis("Horizontal") * _speedFactor;

	    Vector3 position = _rendererTransform.position;

	    Vector3 grad = SimplexNoise3d.snoise(new float3(position.x * _scale + Time.time * _offset.x, position.y * _scale + Time.time * _offset.y, 0.0f + Time.time * _offset.z)).xyz;
	    Vector3 grad1 = Vector3.forward; //SimplexNoise3d.snoise(new float3(position.x * _scale, position.y * _scale, 0.0f) + new float3(15.3f, 13.1f, 17.4f)).xyz;

	    grad = Vector3.Cross( grad, grad1);

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
		}

		_velocity = grad * _speed;
	    
	    _rendererTransform.Translate(_velocity);
	}
	


    private void OnDrawGizmosSelected()
    {
	    int i = 0;
	    for (float x = -_size.x; x < _size.x; x += _step)
	    {
		    for (float y = -_size.y; y < _size.y; y += _step)
		    {
				Gizmos.color = Color.red;
			    if (i++ > 1000000)
			    {
				    return;
			    }

			    Vector3 position = new Vector3(x, y, 0);

			    Vector3 grad = SimplexNoise3d.snoise(new float3(position.x * _scale + Time.time * _offset.x, position.y * _scale + Time.time * _offset.y, 0.0f + Time.time * _offset.z)).xyz;
			    Vector3 grad1 = Vector3.forward;//SimplexNoise3d.snoise(new float3(x * _scale, y * _scale, 0.0f) + new float3(15.3f, 13.1f, 17.4f)).xyz;

				if (_isDivergenceFree)
			    {
				    grad =  Vector3.Cross(grad, grad1);
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
				}

				Gizmos.DrawRay(position, grad * _vectorScale);
		    }
	    }

		Gizmos.color = Color.cyan;
	    Gizmos.DrawRay(_rendererTransform.position, _velocity * _vectorScale * 50f);
		//Gizmos.color = Color.blue;
	    //Gizmos.DrawRay(_rendererTransform.position, _rendererTransform.velocity * _vectorScale * 100);
	}


}
